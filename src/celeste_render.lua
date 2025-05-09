local autotiler = require("autotiler")
local drawing = require("utils.drawing")
local fileLocations = require("file_locations")
local colors = require("consts.colors")
local tasks = require("utils.tasks")
local utils = require("utils")
local atlases = require("atlases")
local smartDrawingBatch = require("structs.smart_drawing_batch")
local drawableRectangle = require("structs.drawable_rectangle")
local viewportHandler = require("viewport_handler")
local matrix = require("utils.matrix")
local configs = require("configs")
local bit = require("bit")
local modHandler = require("mods")
local depths = require("consts.object_depths")
local logging = require("logging")
local modificationWarner = require("modification_warner")

local entityHandler = require("entities")
local triggerHandler = require("triggers")
local decalHandler = require("decals")

local celesteRender = {}

local tilesetFileFg = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Graphics", "ForegroundTiles.xml")
local tilesetFileBg = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Graphics", "BackgroundTiles.xml")

celesteRender.tilesMetaFgVanilla = autotiler.loadTilesetXML(tilesetFileFg)
celesteRender.tilesMetaBgVanilla = autotiler.loadTilesetXML(tilesetFileBg)

celesteRender.tilesMetaFg = celesteRender.tilesMetaFgVanilla
celesteRender.tilesMetaBg = celesteRender.tilesMetaBgVanilla

celesteRender.tilesSpriteMetaCache = {}
celesteRender.tilesSceneryMetaCache = {}

local tilesFgDepth = depths.fgTerrain
local tilesBgDepth = depths.bgTerrain

local decalsFgDepth = depths.fgDecals
local decalsBgDepth = depths.bgDecals

local triggersDepth = depths.triggers

-- TODO - Figure out good number
local YIELD_RATE = 100
local PRINT_BATCHING_DURATION = false
local ALWAYS_REDRAW_UNSELECTED_ROOMS = configs.editor.alwaysRedrawUnselectedRooms
local ALLOW_NON_VISIBLE_BACKGROUND_DRAWING = configs.editor.prepareRoomRenderInBackground

local SCENERY_GAMEPLAY_PATH = "tilesets/scenery"

local roomCache = {}
local roomRandomMatrixCache = {}

local batchingTasks = {}

local function loadCustomAutotiler(filename)
    if filename and filename ~= ""  then
        local commonFilename = modHandler.commonModContent .. "/" .. utils.convertToUnixPath(filename)
        local loaded, tilesMeta = pcall(autotiler.loadTilesetXML, commonFilename)

        return loaded, tilesMeta
    end
end

function celesteRender.loadCustomTilesetAutotiler(state)
    celesteRender.tilesMetaFg = celesteRender.tilesMetaFgVanilla
    celesteRender.tilesMetaBg = celesteRender.tilesMetaBgVanilla

    if state and state.side and state.side.meta then
        local pathFg = state.side.meta.ForegroundTiles
        local pathBg = state.side.meta.BackgroundTiles

        local loadedFg, tilesMetaFg = loadCustomAutotiler(pathFg)
        local loadedBg, tilesMetaBg = loadCustomAutotiler(pathBg)

        if loadedFg then
            celesteRender.tilesMetaFg = tilesMetaFg

        else
            if tilesMetaFg then
                logging.warning(string.format("Loading custom foreground tile XML failed: %s", tilesMetaFg))
            end
        end

        if loadedBg then
            celesteRender.tilesMetaBg = tilesMetaBg

        else
            if tilesMetaBg then
                logging.warning(string.format("Loading custom background tile XML failed: %s", tilesMetaBg))
            end
        end
    end

    celesteRender.clearTileSpriteQuadCache()
    celesteRender.clearScenerySpriteQuadCache()
end

local function getOrCreateSmartBatch(batches, key)
    batches[key] = batches[key] or smartDrawingBatch.createOrderedBatch()

    return batches[key]
end

function celesteRender.sortBatchingTasks(state, taskList)
    local visibleTasks = {}
    local nonVisibileTasks = {}

    for i = #taskList, 1, -1 do
        local task = taskList[i]
        local viewport = state.viewport
        local room = task.data.room

        local roomExists = false

        for _, r in ipairs(state.map.rooms) do
            if r.name == room.name then
                roomExists = true
            end
        end

        if not task.done and roomExists then
            if viewport.visible and viewportHandler.roomVisible(room, viewport) then
                table.insert(visibleTasks, task)

            else
                table.insert(nonVisibileTasks, task)
            end

        else
            table.remove(taskList, i)
        end
    end

    return visibleTasks, nonVisibileTasks
end

function celesteRender.processTasks(state, calcTime, maxTasks, backgroundTime, backgroundTasks)
    local visible, notVisible = celesteRender.sortBatchingTasks(state, batchingTasks)

    backgroundTime = backgroundTime or calcTime
    backgroundTasks = backgroundTasks or maxTasks

    local success, timeSpent, tasksDone = tasks.processTasks(calcTime, maxTasks, visible)
    tasks.processTasks(backgroundTime - timeSpent, backgroundTasks - tasksDone, notVisible)
end

function celesteRender.clearBatchingTasks()
    -- TODO - Check if this should release the ongoing tasks or if Lua GC is good enough
    batchingTasks = {}
end

function celesteRender.releaseBatch(roomName, key)
    if roomCache[roomName] and roomCache[roomName][key] and roomCache[roomName][key].result then
        local target = roomCache[roomName][key].result

        if utils.typeof(target) == "table" then
            for depth, depthTarget in pairs(target) do
                if depthTarget.release then
                    depthTarget:release()
                end
            end

        else
            if target.release then
                target:release()
            end
        end
    end
end

function celesteRender.invalidateRoomCache(roomName, key)
    if roomName then
        if utils.typeof(roomName) == "room" then
            roomName = roomName.name
        end

        if roomCache[roomName] then
            if key then
                if type(key) == "table" then
                    for _, k in ipairs(key) do
                        celesteRender.releaseBatch(roomName, k)

                        roomCache[roomName][k] = nil
                    end

                else
                    celesteRender.releaseBatch(roomName, key)

                    roomCache[roomName][key] = nil
                end

            else
                for name, task in pairs(roomCache[roomName]) do
                    celesteRender.releaseBatch(roomName, name)
                end

                roomCache[roomName] = nil
            end
        end

    else
        for name, _ in pairs(roomCache) do
            celesteRender.invalidateRoomCache(name)
        end

        roomCache = {}
    end
end

function celesteRender.getRoomRandomMatrix(room, key)
    local roomName = room.name
    local tileWidth, tileHeight = room[key].matrix:size()
    local regen = false

    if roomRandomMatrixCache[roomName] and roomRandomMatrixCache[roomName][key] then
        local m = roomRandomMatrixCache[roomName][key]
        local randWidth, randHeight = m:size()

        regen = tileWidth ~= randWidth or tileHeight ~= randHeight

    else
        regen = true
    end

    if regen then
        utils.setRandomSeed(roomName)

        local m = matrix.fromFunction(math.random, tileWidth, tileHeight)

        roomRandomMatrixCache[roomName] = roomRandomMatrixCache[roomName] or {}
        roomRandomMatrixCache[roomName][key] = m
    end

    return roomRandomMatrixCache[roomName][key]
end

function celesteRender.getRoomCache(roomName, key)
    if utils.typeof(roomName) == "room" then
        roomName = roomName.name
    end

    if roomCache[roomName] and roomCache[roomName][key] then
        return roomCache[roomName][key]
    end

    return false
end

function celesteRender.getRoomBackgroundColor(room, selected, state)
    if not state.showRoomBackground then
        return nil
    end

    local roomColor = room.color or 0
    local color = colors.roomBackgroundDefault

    if roomColor >= 0 and roomColor < #colors.roomBackgroundColors then
        color = colors.roomBackgroundColors[roomColor + 1]
    end

    local r, g, b = color[1], color[2], color[3]
    local a = selected and 1.0 or 0.3

    return {r, g, b, a}
end

function celesteRender.getRoomBorderColor(room, selected, state)
    if not state.showRoomBorders then
        return nil
    end

    local roomColor = room.color or 0
    local color = colors.roomBorderDefault

    if roomColor >= 0 and roomColor < #colors.roomBorderColors then
        color = colors.roomBorderColors[roomColor + 1]
    end

    return color
end

function celesteRender.getSceneryMeta()
    return atlases.gameplay[SCENERY_GAMEPLAY_PATH]
end

function celesteRender.clearTileSpriteQuadCache()
    -- TODO - Does this need to release quads? Should be small enough to just wait for Lua GC

    celesteRender.tilesSpriteMetaCache = {}
end

function celesteRender.clearScenerySpriteQuadCache()
    -- TODO - Does this need to release quads? Should be small enough to just wait for Lua GC

    celesteRender.tilesSceneryMetaCache = nil
end

function celesteRender.getOrCacheTileSpriteQuad(cache, tile, texture, quad, fg)
    if not cache[tile] then
        local tilesetSpriteMeta = atlases.gameplay[texture]
        local tilesetSpriteWidth, tilesetSpriteHeight = tilesetSpriteMeta.realWidth, tilesetSpriteMeta.realHeight
        local width, height = math.ceil(tilesetSpriteWidth / 8), math.ceil(tilesetSpriteHeight / 8)

        cache[tile] = {
            [false] = matrix.filled(nil, width, height),
            [true] = matrix.filled(nil, width, height)
        }
    end

    local quadCache = cache[tile][fg]
    local quadX, quadY = quad[1], quad[2]

    local cachedQuad = quadCache:get0(quadX, quadY, false)

    if not cachedQuad then
        local spriteMeta = atlases.gameplay[texture]
        local spritesWidth, spritesHeight = spriteMeta.image:getDimensions()
        local res = love.graphics.newQuad(spriteMeta.x - spriteMeta.offsetX + quadX * 8, spriteMeta.y - spriteMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)

        quadCache:set0(quadX, quadY, res)

        return res
    end

    return cachedQuad
end

function celesteRender.getOrCacheScenerySpriteQuad(index)
    local sceneryMeta = celesteRender.getSceneryMeta()
    local sceneryWidth, sceneryHeight = math.ceil(sceneryMeta.realWidth / 8), math.ceil(sceneryMeta.realHeight / 8)
    local quadX, quadY = index % sceneryWidth, math.floor(index / sceneryWidth)

    if not celesteRender.tilesSceneryMetaCache then
        celesteRender.tilesSceneryMetaCache = matrix.filled(nil, sceneryWidth, sceneryHeight)
    end

    local quadCache = celesteRender.tilesSceneryMetaCache

    if not quadCache:get0(quadX, quadY) then
        local spritesWidth, spritesHeight = sceneryMeta.image:getDimensions()
        local quad = love.graphics.newQuad(sceneryMeta.x - sceneryMeta.offsetX + quadX * 8, sceneryMeta.y - sceneryMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)

        quadCache:set0(quadX, quadY, quad)

        return quad
    end

    return quadCache:get0(quadX, quadY)
end

function celesteRender.drawInvalidTiles(batch, missingTiles, fg)
    if #missingTiles > 0 then
        local batchType = utils.typeof(batch)

        if batchType == "gridCanvasDrawingBatch" then
            local color = fg and colors.tileFGMissingColor or colors.tileBGMissingColor

            local canvas = love.graphics.getCanvas()
            local r, g, b, a = love.graphics.getColor()

            love.graphics.setCanvas(batch._canvas)
            love.graphics.setColor(color)

            for _, missing in ipairs(missingTiles) do
                local x, y = missing[1], missing[2]

                love.graphics.rectangle("fill", x * 8 - 8, y * 8 - 8, 8, 8)
            end

            love.graphics.setCanvas(canvas)
            love.graphics.setColor(r, g, b, a)

        elseif batchType == "matrixDrawingBatch" then
            local pixelTexture = atlases.addInternalPrefix(drawableRectangle.tintingPixelTexture)
            local pixelMeta = atlases.getResource(pixelTexture, "Gameplay")
            local color = fg and colors.tileFGMissingColor or colors.tileBGMissingColor
            local defaultColor = {1.0, 1.0, 1.0, 1.0}

            for _, missing in ipairs(missingTiles) do
                local x, y = missing[1], missing[2]
                local drawX, drawY = x * 8 - 8, y * 8 - 8

                batch:setColor(pixelMeta, color)
                batch:set(x, y, pixelMeta, pixelMeta.quad, drawX, drawY, 0, 8, 8)
            end

            batch:setColor(pixelMeta, defaultColor)
        end
    end
end

local function getTilesBatchFromMode(width, height, mode)
    if mode == "gridCanvasDrawingBatch" then
        return smartDrawingBatch.createGridCanvasBatch(false, width, height, 8, 8)

    elseif mode == "matrixDrawingBatch" then
        return smartDrawingBatch.createMatrixBatch(false, width, height, 8, 8)

    elseif mode == "table" then
        return {}
    end
end

-- randomMatrix is for custom randomness, mostly to give the correct "slice" of the matrix when making fake tiles
function celesteRender.getTilesBatch(room, tiles, meta, scenery, fg, randomMatrix, batchMode, shouldYield)
    batchMode = batchMode or "matrixDrawingBatch"

    local tilesMatrix = tiles.matrix

    -- Getting upvalues
    local tileCache = celesteRender.tilesSpriteMetaCache
    local autotiler = autotiler
    local meta = meta
    local checkTile = autotiler.checkTile
    local lshift = bit.lshift
    local bxor = bit.bxor
    local band = bit.band

    local airTile = "0"
    local emptyTile = " "
    local wildcard = "*"

    local defaultQuad = {{0, 0}}
    local defaultSprite = ""

    local width, height = tilesMatrix:size()
    local batch = getTilesBatchFromMode(width, height, batchMode)

    local random = randomMatrix or celesteRender.getRoomRandomMatrix(room, fg and "tilesFg" or "tilesBg")

    local sceneryMatrix = scenery and scenery.matrix or matrix.filled(-1, width, height)
    local sceneryMeta = celesteRender.getSceneryMeta()
    local sceneryWidth, sceneryHeight = sceneryMeta.realWidth, sceneryMeta.realHeight

    local missingTiles = {}

    for x = 1, width do
        for y = 1, height do
            local rng = random:getInbounds(x, y)
            local tile = tilesMatrix:getInbounds(x, y) or airTile
            local sceneryTile = sceneryMatrix:getInbounds(x, y) or -1

            if sceneryTile > -1 then
                local quad = celesteRender.getOrCacheScenerySpriteQuad(sceneryTile)

                if quad then
                    if batchMode == "gridCanvasDrawingBatch" or batchMode == "matrixDrawingBatch" then
                        batch:set(x, y, sceneryMeta, quad, x * 8 - 8, y * 8 - 8)

                    elseif batchMode == "table" then
                        table.insert(batch, {sceneryMeta, quad, x * 8 - 8, y * 8 - 8})
                    end
                end

            elseif tile ~= airTile then
                local tileMeta = meta[tile]
                if tileMeta and tileMeta.path then
                    -- TODO - Render overlay sprites
                    local quads, sprites = autotiler.getQuads(x, y, tilesMatrix, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite, checkTile, lshift, bxor, band)
                    local quadCount = #quads

                    if quadCount > 0 then
                        local randQuad = quads[utils.mod1(rng, quadCount)]
                        local texture = tileMeta.path or emptyTile

                        local spriteMeta = atlases.gameplay[texture]

                        if spriteMeta then
                            local quad = celesteRender.getOrCacheTileSpriteQuad(tileCache, tile, texture, randQuad, fg)

                            if batchMode == "gridCanvasDrawingBatch" or batchMode == "matrixDrawingBatch" then
                                batch:set(x, y, spriteMeta, quad, x * 8 - 8, y * 8 - 8)

                            elseif batchMode == "table" then
                                table.insert(batch, {spriteMeta, quad, x * 8 - 8, y * 8 - 8})
                            end

                        else
                            -- Missing texture, not found on disk
                            table.insert(missingTiles, {x, y})
                        end
                    end

                else
                    -- Unknown tileset id
                    table.insert(missingTiles, {x, y})
                end
            end
        end

        if shouldYield ~= false then
            tasks.yield()
        end
    end

    celesteRender.drawInvalidTiles(batch, missingTiles, fg)

    if shouldYield ~= false then
        tasks.update(batch)
    end

    return batch, missingTiles
end

local function getRoomTileBatch(room, tiles, fg)
    local key = fg and "tilesFg" or "tilesBg"
    local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local scenery = fg and room.sceneryFg or room.sceneryBg

    local roomName = room.name
    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if not cache[key]then
        cache[key] = tasks.newTask(
            (-> celesteRender.getTilesBatch(room, tiles, meta, scenery, fg)),
            (task -> PRINT_BATCHING_DURATION and logging.info(string.format("Batching '%s' in '%s' took %s ms", key, room.name, task.timeTotal * 1000))),
            batchingTasks,
            {room = room}
        )
    end

    return cache[key].result
end

function celesteRender.getTilesFgBatch(room, tiles, viewport)
    return getRoomTileBatch(room, tiles, true)
end

function celesteRender.getTilesBgBatch(room, tiles, viewport)
    return getRoomTileBatch(room, tiles, false)
end

local function getDecalsBatchTaskFunc(decals, room, fg, viewport)
    local batches = {}

    for i, decal in ipairs(decals) do
        local renderDecal = decalHandler.renderFilterPredicate(room, decal, fg)

        if renderDecal then
            local texture = decal.texture
            local drawable, depth = decalHandler.getDrawable(texture, nil, room, decal, viewport)

            if drawable then
                local defaultDepth = fg and decalsFgDepth or decalsBgDepth
                local batchDepth = depth or defaultDepth
                local batch = getOrCreateSmartBatch(batches, batchDepth)

                batch:addFromDrawable(drawable)
            end
        end

        if i % YIELD_RATE == 0 then
            tasks.yield()
        end
    end

    tasks.update(batches)

    return batches
end

local function getRoomDecalsBatch(room, decals, fg, viewport)
    local key = fg and "decalsFg" or "decalsBg"

    local roomName = room.name
    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if not cache[key]then
        cache[key] = tasks.newTask(
            (-> getDecalsBatchTaskFunc(decals, room, fg, viewport)),
            (task -> PRINT_BATCHING_DURATION and logging.info(string.format("Batching '%s' in '%s' took %s ms", key, room.name, task.timeTotal * 1000))),
            batchingTasks,
            {room = room}
        )
    end

    return cache[key].result
end

function celesteRender.getDecalsFgBatch(room, decals, viewport)
    return getRoomDecalsBatch(room, decals, true)
end

function celesteRender.getDecalsBgBatch(room, decals, viewport)
    return getRoomDecalsBatch(room, decals, false)
end

function celesteRender.drawDecalsFg(room, decals)
    local batch = celesteRender.getDecalsFgBatch(room, decals)

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

function celesteRender.drawDecalsBg(room, decals)
    local batch = celesteRender.getDecalsBgBatch(room, decals)

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

local function getEntityBatchTaskFunc(room, entities, viewport, registeredEntities)
    local batches = {}

    for i, entity in ipairs(entities) do
        local name = entity._name
        local handler = registeredEntities[name]

        if handler then
            local renderEntity = entityHandler.renderFilterPredicate(room, entity)

            if renderEntity then
                local drawable, depth = entityHandler.getDrawable(name, handler, room, entity, viewport)

                -- Special case for multiple drawable sprites
                -- Maybe handle this better later
                if drawable then
                    local drawableIsTable = utils.typeof(drawable) == "table"

                    if not drawableIsTable then
                        local batchDepth = drawable.depth or depth or 0
                        local batch = getOrCreateSmartBatch(batches, batchDepth)

                        batch:addFromDrawable(drawable)

                    else
                        for _, drawableItem in ipairs(drawable) do
                            local batchDepth = drawableItem.depth or depth or 0
                            local batch = getOrCreateSmartBatch(batches, batchDepth)

                            batch:addFromDrawable(drawableItem)
                        end
                    end
                end

                if i % YIELD_RATE == 0 then
                    tasks.yield()
                end
            end
        end
    end

    tasks.update(batches)

    return batches
end

function celesteRender.getEntityBatch(room, entities, viewport, registeredEntities, forceRedraw)
    registeredEntities = registeredEntities or entityHandler.registeredEntities

    local roomName = room.name
    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if forceRedraw and cache.entities.result ~= nil then
        cache.entities = nil
    end

    if not cache.entities then
        cache.entities = tasks.newTask(
            (-> getEntityBatchTaskFunc(room, entities, viewport, registeredEntities)),
            (task -> PRINT_BATCHING_DURATION and logging.info(string.format("Batching 'entities' in '%s' took %s ms", room.name, task.timeTotal * 1000))),
            batchingTasks,
            {room = room}
        )
    end

    return cache.entities.result
end

local function getTriggerBatchTaskFunc(room, triggers, viewport, registeredTriggers)
    local batches = {}

    for i, trigger in ipairs(triggers) do
        local name = trigger._name
        local handler = registeredTriggers[name]

        if handler then
            local renderTrigger = triggerHandler.renderFilterPredicate(room, trigger)

            if renderTrigger then
                local drawable, depth = triggerHandler.getDrawable(name, handler, room, trigger, viewport)

                -- Special case for multiple drawable sprites
                -- Maybe handle this better later
                if drawable then
                    local drawableIsTable = utils.typeof(drawable) == "table"

                    if not drawableIsTable then
                        local batchDepth = drawable.depth or depth or 0
                        local batch = getOrCreateSmartBatch(batches, batchDepth)

                        batch:addFromDrawable(drawable)

                    else
                        for _, drawableItem in ipairs(drawable) do
                            local batchDepth = drawableItem.depth or depth or 0
                            local batch = getOrCreateSmartBatch(batches, batchDepth)

                            batch:addFromDrawable(drawableItem)
                        end
                    end
                end

                if i % YIELD_RATE == 0 then
                    tasks.yield()
                end
            end
        end
    end

    tasks.update(batches)

    return batches
end

function celesteRender.getTriggerBatch(room, triggers, viewport, registeredTriggers, forceRedraw)
    registeredTriggers = registeredTriggers or triggerHandler.registeredTriggers

    local roomName = room.name
    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if forceRedraw and cache.triggers.result ~= nil then
        cache.triggers = nil
    end

    if not cache.triggers then
        cache.triggers = tasks.newTask(
            (-> getTriggerBatchTaskFunc(room, triggers, viewport, registeredTriggers)),
            (task -> PRINT_BATCHING_DURATION and logging.info(string.format("Batching 'triggers' in '%s' took %s ms", roomName, task.timeTotal * 1000))),
            batchingTasks,
            {room = room}
        )
    end

    return cache.triggers.result
end

local depthBatchingFunctions = {
    {"Background Tiles", "tilesBg", celesteRender.getTilesBgBatch, tilesBgDepth},
    {"Background Decals", "decalsBg", celesteRender.getDecalsBgBatch},
    {"Entities", "entities", celesteRender.getEntityBatch},
    {"Foreground Tiles", "tilesFg", celesteRender.getTilesFgBatch, tilesFgDepth},
    {"Foreground Decals", "decalsFg", celesteRender.getDecalsFgBatch},
    {"Triggers", "triggers", celesteRender.getTriggerBatch}
}

-- Force all non finished room batch tasks to finish
function celesteRender.forceRoomBatchRender(room, state)
    local viewport = state.viewport

    for i, data in ipairs(depthBatchingFunctions) do
        local description, key, func, depth = data[1], data[2], data[3], data[4]
        local layerVisible = state.getLayerShouldRender(key)
        local result = func(room, room[key], viewport)
        local task = roomCache[room.name][key]

        if layerVisible and not result and task then
            tasks.processTask(task)
        end
    end
end

local function addBatch(depthBatches, depth, batches)
    local batchTarget = depthBatches[depth]
    local batchesIsTable = utils.typeof(batches) == "table"

    if batchTarget then
        if batchesIsTable then
            for _, sprite in ipairs(batches) do
                table.insert(batchTarget, sprite)
            end

        else
            table.insert(batchTarget, batches)
        end

    else
        if batchesIsTable then
            depthBatches[depth] = batches

        else
            depthBatches[depth] = {batches}
        end
    end
end

function celesteRender.getRoomBatches(room, state)
    local roomName = room.name
    local cache = roomCache[roomName]
    local viewport = state.viewport

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if not cache.complete then
        local depthBatches = {}
        local done = true

        for i, data in ipairs(depthBatchingFunctions) do
            local description, key, func, depth = data[1], data[2], data[3], data[4]
            local layerVisible = state.getLayerShouldRender(key)
            local batches

            if layerVisible then
                batches = func(room, room[key], viewport)
            end

            if batches then
                local batchesIsTable = utils.typeof(batches) == "table"

                if not batchesIsTable then
                    addBatch(depthBatches, depth or 0, batches)

                else
                    for d, batch in pairs(batches) do
                        addBatch(depthBatches, d, batch)
                    end
                end

            else
                if layerVisible then
                    done = false
                end
            end
        end

        -- Not done, but all the tasks have been started
        -- Attempt to render other rooms while we wait
        if not done then
            return false
        end

        local orderedBatches = {}

        for depth, batches in pairs(depthBatches) do
            table.insert(orderedBatches, {depth, batches})
        end

        table.sort(orderedBatches, function(lhs, rhs)
            return lhs[1] > rhs[1]
        end)

        for i, pair in ipairs(orderedBatches) do
            orderedBatches[i] = pair[2]
        end

        cache.complete = orderedBatches
    end

    return cache.complete
end

local function drawRoomFromBatches(room, state, selected)
    local orderedBatches = celesteRender.getRoomBatches(room, state)

    if orderedBatches then
        for _, batch in ipairs(orderedBatches) do
            for _, drawable in ipairs(batch) do
                drawable:draw()
            end
        end
    end
end

-- Return the canvas if it is ready, otherwise make a task for it
local function getRoomCanvas(room, state, selected)
    local viewport = state.viewport
    local orderedBatches = celesteRender.getRoomBatches(room, state)
    local roomName = room.name

    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if orderedBatches and not cache.canvas then
        cache.canvas = tasks.newTask(
            function(task)
                local canvas = love.graphics.newCanvas(room.width or 0, room.height or 0)

                canvas:renderTo(function()
                    for depth, batch in ipairs(orderedBatches) do
                        for _, drawable in ipairs(batch) do
                            drawable:draw()
                        end
                    end
                end)

                tasks.update(canvas)
            end,
            nil,
            batchingTasks,
            {room = room}
        )
    end

    return cache.canvas and cache.canvas.result, cache.canvas
end

-- Force the rooms canvas cache to be rendered
function celesteRender.forceRoomCanvasRender(room, state, selected)
    local canvas, task = getRoomCanvas(room, state, selected)

    if not canvas then
        tasks.processTask(task)
    end
end

function celesteRender.forceRedrawRoom(room, state, selected)
    local viewport = state.viewport

    celesteRender.invalidateRoomCache(room)
    celesteRender.forceRoomBatchRender(room, state)
    celesteRender.forceRoomCanvasRender(room, state, selected)
end

function celesteRender.forceRedrawVisibleRooms(rooms, state, selectedItem, selectedItemType)
    local viewport = state.viewport

    for _, room in ipairs(rooms) do
        local roomVisible = viewportHandler.roomVisible(room, viewport)
        local roomVisibleWidth, roomVisibleHeight = viewportHandler.getRoomVisibleSize(room, viewport)
        local selected = room == selectedItem

        if selectedItemType == "table" then
            selected = selectedItem[room]
        end

        -- No need to redraw immidietly if only the borders are visible
        if roomVisible and roomVisibleWidth > 2 and roomVisibleHeight > 2 then
            celesteRender.forceRoomBatchRender(room, state)
            celesteRender.forceRoomCanvasRender(room, state, selected)
        end
    end
end

function celesteRender.drawRooms(rooms, state, selectedItem, selectedItemType)
    local viewport = state.viewport

    for _, room in ipairs(rooms) do
        local roomVisible = viewportHandler.roomVisible(room, viewport)
        local selected = room == selectedItem

        if selectedItemType == "table" then
            selected = selectedItem[room]
        end

        if ALLOW_NON_VISIBLE_BACKGROUND_DRAWING or roomVisible then
            celesteRender.drawRoom(room, state, selected, roomVisible)
        end
    end
end

function celesteRender.drawRoom(room, state, selected, visible)
    -- Getting the canvas starts background drawing tasks
    -- This should start regardless of the room being visible or not
    local redrawRoom = selected or ALWAYS_REDRAW_UNSELECTED_ROOMS
    local viewport = state.viewport
    local canvas = not redrawRoom and getRoomCanvas(room, state, selected)

    if visible or selected then
        local roomX = room.x or 0
        local roomY = room.y or 0

        local width = room.width or 40 * 8
        local height = room.height or 23 * 8

        local roomVisibleWidth, roomVisibleHeight = viewportHandler.getRoomVisibleSize(room, viewport)

        local backgroundColor = celesteRender.getRoomBackgroundColor(room, selected, state)
        local borderColor = celesteRender.getRoomBorderColor(room, selected, state)

        viewportHandler.drawRelativeTo(roomX, roomY, function()
            if backgroundColor then
                drawing.callKeepOriginalColor(function()
                    love.graphics.setColor(backgroundColor)
                    love.graphics.rectangle("fill", 0, 0, width, height)
                end)
            end

            if redrawRoom then
                drawRoomFromBatches(room, state, selected)

            else
                if canvas then
                    -- No need to draw the canvas if we can only see the border
                    if roomVisibleWidth > 2 and roomVisibleHeight > 2 then
                        love.graphics.draw(canvas)
                    end
                end
            end

            if borderColor then
                drawing.callKeepOriginalColor(function()
                    love.graphics.setColor(borderColor)
                    love.graphics.rectangle("line", 0, 0, width, height)
                end)
            end
        end, viewport)
    end
end

-- Iterate over twice
-- Batch draw all selected and unselected fillers
function celesteRender.drawFillers(fillers, state, selectedItem, selectedItemType)
    local pr, pb, pg, pa = love.graphics.getColor()
    local multipleSelections = selectedItemType == "table"
    local viewport = state.viewport

    -- Unselected fillers
    love.graphics.setColor(colors.fillerColor)

    for i, filler in ipairs(fillers) do
        if not (multipleSelections and selectedItem[filler] or selectedItem == filler) then
            if viewportHandler.fillerVisible(filler, viewport) then
                celesteRender.drawFiller(filler, viewport)
            end
        end
    end

    -- Selected fillers
    love.graphics.setColor(colors.fillerSelectedColor)

    for i, filler in ipairs(fillers) do
        if multipleSelections and selectedItem[filler] or selectedItem == filler then
            if viewportHandler.fillerVisible(filler, viewport) then
                celesteRender.drawFiller(filler, viewport)
            end
        end
    end

    love.graphics.setColor(pr, pb, pg, pa)
end

function celesteRender.drawFiller(filler, viewport)
    local x = filler.x * 8
    local y = filler.y * 8

    local width = filler.width * 8
    local height = filler.height * 8

    viewportHandler.drawRelativeTo(x, y, function()
        love.graphics.rectangle("fill", 0, 0, width, height)
    end, viewport)
end

function celesteRender.drawMap(state)
    if state and state.map then
        local map = state.map
        local viewport = state.viewport

        if viewport.visible then
            local selectedItem, selectedItemType = state.getSelectedItem()

            celesteRender.drawFillers(map.fillers, state, selectedItem, selectedItemType)
            celesteRender.drawRooms(map.rooms, state, selectedItem, selectedItemType)
        end
    end
end

modificationWarner.addModificationWarner(celesteRender)

return celesteRender