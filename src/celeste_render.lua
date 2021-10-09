local autotiler = require("autotiler")
local drawing = require("utils.drawing")
local fileLocations = require("file_locations")
local colors = require("consts.colors")
local tasks = require("utils.tasks")
local utils = require("utils")
local atlases = require("atlases")
local smartDrawingBatch = require("structs.smart_drawing_batch")
local viewportHandler = require("viewport_handler")
local matrix = require("utils.matrix")
local configs = require("configs")
local bit = require("bit")
local modHandler = require("mods")
local depths = require("consts.object_depths")

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
                print("Loading custom foreground tile XML failed: ", tilesMetaFg)
            end
        end

        if loadedBg then
            celesteRender.tilesMetaBg = tilesMetaBg

        else
            if tilesMetaBg then
                print("Loading custom background tile XML failed: ", tilesMetaBg)
            end
        end
    end
end

function celesteRender.sortBatchingTasks(state, tasks)
    local visibleTasks = {}
    local nonVisibileTasks = {}

    for i = #batchingTasks, 1, -1 do
        local task = batchingTasks[i]
        local viewport = state.viewport
        local room = task.data.room

        if not task.done then
            if viewport.visible and viewportHandler.roomVisible(room, viewport) then
                table.insert(visibleTasks, task)

            else
                table.insert(nonVisibileTasks, task)
            end

        else
            table.remove(batchingTasks, i)
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
    batchingTasks = {}
end

function celesteRender.releaseBatch(roomName, key)
    if roomCache[roomName] and roomCache[roomName][key] and roomCache[roomName][key].result then
        local target = roomCache[roomName][key].result

        if target.release then
            target:release()
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
                celesteRender.releaseBatch(roomName, key)

                roomCache[roomName][key] = nil

            else
                for name, task in pairs(roomCache[roomName]) do
                    celesteRender.releaseBatch(roomName, name)
                end

                roomCache[roomName] = {}
            end
        end

    else
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

function celesteRender.getRoomBackgroundColor(room, selected)
    local roomColor = room.color or 0
    local color = colors.roomBackgroundDefault

    if roomColor >= 0 and roomColor < #colors.roomBackgroundColors then
        color = colors.roomBackgroundColors[roomColor + 1]
    end

    local r, g, b = color[1], color[2], color[3]
    local a = selected and 1.0 or 0.3

    return {r, g, b, a}
end

function celesteRender.getRoomBorderColor(room, selected)
    local roomColor = room.color or 0
    local color = colors.roomBorderDefault

    if roomColor >= 0 and roomColor < #colors.roomBorderColors then
        color = colors.roomBorderColors[roomColor + 1]
    end

    return color
end

function celesteRender.getOrCacheTileSpriteQuad(cache, tile, texture, quad, fg)
    if not cache[tile] then
        cache[tile] = {
            [false] = matrix.filled(nil, 6, 15),
            [true] = matrix.filled(nil, 6, 15)
        }
    end

    local quadCache = cache[tile][fg]
    local quadX, quadY = quad[1], quad[2]

    if not quadCache:get0(quadX, quadY) then
        local spriteMeta = atlases.gameplay[texture]
        local spritesWidth, spritesHeight = spriteMeta.image:getDimensions()
        local res = love.graphics.newQuad(spriteMeta.x - spriteMeta.offsetX + quadX * 8, spriteMeta.y - spriteMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)

        quadCache:set0(quadX, quadY, res)

        return res
    end

    return quadCache:get0(quadX, quadY)
end

local function drawInvalidTiles(batch, missingTiles, fg)
    if #missingTiles > 0 then
        if batch._canvas then
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
        end
    end
end

local function getTilesBatchFromMode(width, height, mode)
    if mode == "canvasGrid" then
        return smartDrawingBatch.createGridCanvasBatch(false, width, height, 8, 8)

    elseif mode == "table" then
        return {}
    end
end

-- randomMatrix is for custom randomness, mostly to give the correct "slice" of the matrix when making fake tiles
function celesteRender.getTilesBatch(room, tiles, meta, fg, randomMatrix, batchMode, shouldYield)
    batchMode = batchMode or "canvasGrid"

    local tilesMatrix = tiles.matrix

    -- Getting upvalues
    local cache = celesteRender.tilesSpriteMetaCache
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

    local missingTiles = {}

    for x = 1, width do
        for y = 1, height do
            local rng = random:getInbounds(x, y)
            local tile = tilesMatrix:getInbounds(x, y)

            if tile ~= airTile then
                if meta.paths[tile] then
                    -- TODO - Render overlay sprites
                    local quads, sprites = autotiler.getQuadsWithBitmask(x, y, tilesMatrix, meta, airTile, emptyTile, wildcard, defaultQuad, defaultSprite, checkTile, lshift, bxor, band)
                    local quadCount = #quads

                    if quadCount > 0 then
                        local randQuad = quads[utils.mod1(rng, quadCount)]
                        local texture = meta.paths[tile] or emptyTile

                        local spriteMeta = atlases.gameplay[texture]

                        if spriteMeta then
                            local quad = celesteRender.getOrCacheTileSpriteQuad(cache, tile, texture, randQuad, fg)

                            if batchMode == "canvasGrid" then
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

    drawInvalidTiles(batch, missingTiles, fg)

    if shouldYield ~= false then
        tasks.update(batch)
    end

    return batch, missingTiles
end

local function getRoomTileBatch(room, tiles, fg)
    local key = fg and "tilesFg" or "tilesBg"
    local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg

    local roomName = room.name
    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if not cache[key]then
        cache[key] = tasks.newTask(
            (-> celesteRender.getTilesBatch(room, tiles, meta, fg)),
            (task -> PRINT_BATCHING_DURATION and print(string.format("Batching '%s' in '%s' took %s ms", key, room.name, task.timeTotal * 1000))),
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

local function getDecalsBatchTaskFunc(decals, room, viewport)
    local batch = smartDrawingBatch.createOrderedBatch()

    for i, decal in ipairs(decals) do
        local texture = decal.texture
        local drawable = decalHandler.getDrawable(texture, nil, room, decal, viewport)

        if drawable then
            batch:addFromDrawable(drawable)
        end

        if i % YIELD_RATE == 0 then
            tasks.yield()
        end
    end

    tasks.update(batch)

    return batch
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
            (-> getDecalsBatchTaskFunc(decals, room, viewport)),
            (task -> PRINT_BATCHING_DURATION and print(string.format("Batching '%s' in '%s' took %s ms", key, room.name, task.timeTotal * 1000))),
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

local function getOrCreateSmartBatch(batches, key)
    batches[key] = batches[key] or smartDrawingBatch.createOrderedBatch()

    return batches[key]
end

local function getEntityBatchTaskFunc(room, entities, viewport, registeredEntities)
    local batches = {}

    for i, entity in ipairs(entities) do
        local name = entity._name
        local handler = registeredEntities[name]

        if handler then
            local drawable, depth = entityHandler.getDrawable(name, handler, room, entity, viewport)

            -- Special case for multiple drawable sprites
            -- Maybe handle this better later
            if drawable then
                if #drawable == 0 then
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
            (task -> PRINT_BATCHING_DURATION and print(string.format("Batching 'entities' in '%s' took %s ms", room.name, task.timeTotal * 1000))),
            batchingTasks,
            {room = room}
        )
    end

    return cache.entities.result
end

local function getTriggerBatchTaskFunc(room, triggers, viewport)
    local batch = smartDrawingBatch.createOrderedBatch()

    triggerHandler.addDrawables(batch, room, triggers, viewport, YIELD_RATE)
    tasks.update(batch)

    return batch
end

function celesteRender.getTriggerBatch(room, triggers, viewport, forceRedraw)
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
            (-> getTriggerBatchTaskFunc(room, triggers, viewport)),
            (task -> PRINT_BATCHING_DURATION and print(string.format("Batching 'triggers' in '%s' took %s ms", roomName, task.timeTotal * 1000))),
            batchingTasks,
            {room = room}
        )
    end

    return cache.triggers.result
end

function celesteRender.drawTriggers(room, triggers, viewport)
    local batch = celesteRender.getTriggerBatch(room, triggers, viewport)

    batch:draw()
end

local depthBatchingFunctions = {
    {"Background Tiles", "tilesBg", celesteRender.getTilesBgBatch, tilesBgDepth},
    {"Background Decals", "decalsBg", celesteRender.getDecalsBgBatch, decalsBgDepth},
    {"Entities", "entities", celesteRender.getEntityBatch},
    {"Foreground Tiles", "tilesFg", celesteRender.getTilesFgBatch, tilesFgDepth},
    {"Foreground Decals", "decalsFg", celesteRender.getDecalsFgBatch, decalsFgDepth},
    {"Triggers", "triggers", celesteRender.getTriggerBatch, triggersDepth}
}

-- Force all non finished room batch tasks to finish
function celesteRender.forceRoomBatchRender(room, viewport)
    for i, data in ipairs(depthBatchingFunctions) do
        local description, key, func, depth = data[1], data[2], data[3], data[4]
        local result = func(room, room[key], viewport)
        local task = roomCache[room.name][key]

        if not result and task then
            tasks.processTask(task)
        end
    end
end

local function addBatch(depthBatches, depth, batches)
    local batchTarget = depthBatches[depth]

    if batchTarget then
        if #batches > 0 then
            for _, sprite in ipairs(batches) do
                table.insert(batchTarget, sprite)
            end

        else
            table.insert(batchTarget, batches)
        end

    else
        if #batches > 0 then
            depthBatches[depth] = batches

        else
            depthBatches[depth] = {batches}
        end
    end
end

function celesteRender.getRoomBatches(room, viewport)
    local roomName = room.name
    local cache = roomCache[roomName]

    if not cache then
        cache = {}
        roomCache[roomName] = cache
    end

    if not cache.complete then
        local depthBatches = {}
        local done = true

        for i, data in ipairs(depthBatchingFunctions) do
            local description, key, func, depth = data[1], data[2], data[3], data[4]
            local batches = func(room, room[key], viewport)

            if batches then
                if depth then
                    addBatch(depthBatches, depth, batches)

                else
                    for d, batch in pairs(batches) do
                        addBatch(depthBatches, d, batch)
                    end
                end

            else
                done = false
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

local function drawRoomFromBatches(room, viewport, selected)
    local orderedBatches = celesteRender.getRoomBatches(room, viewport)

    if orderedBatches then
        for depth, batch in ipairs(orderedBatches) do
            for _, drawable in ipairs(batch) do
                drawable:draw()
            end
        end
    end
end

-- Return the canvas if it is ready, otherwise make a task for it
local function getRoomCanvas(room, viewport, selected)
    local orderedBatches = celesteRender.getRoomBatches(room, viewport)
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

    return cache.canvas and cache.canvas.result
end

-- Force the rooms canvas cache to be rendered
function celesteRender.forceRoomCanvasRender(room, viewport, selected)
    local task, canvas = getRoomCanvas(room, viewport, selected)

    if task and not canvas then
        tasks.processTask(task)
    end
end

function celesteRender.forceRedrawRoom(room, viewport, selected)
    celesteRender.invalidateRoomCache(room)
    celesteRender.forceRoomBatchRender(room, viewport)
    celesteRender.forceRoomCanvasRender(room, viewport, selected)
end

function celesteRender.drawRooms(rooms, viewport, selectedItem, selectedItemType)
    for _, room in ipairs(rooms) do
        local roomVisible = viewportHandler.roomVisible(room, viewport)
        local selected = room == selectedItem

        if selectedItemType == "table" then
            selected = selectedItem[room]
        end

        if ALLOW_NON_VISIBLE_BACKGROUND_DRAWING or roomVisible then
            celesteRender.drawRoom(room, viewport, selected, roomVisible)
        end
    end
end

function celesteRender.drawRoom(room, viewport, selected, visible)
    -- Getting the canvas starts background drawing tasks
    -- This should start regardless of the room being visible or not
    local redrawRoom = selected or ALWAYS_REDRAW_UNSELECTED_ROOMS
    local canvas = not redrawRoom and getRoomCanvas(room, viewport, selected)

    if visible or selected then
        local roomX = room.x or 0
        local roomY = room.y or 0

        local width = room.width or 40 * 8
        local height = room.height or 23 * 8

        local roomVisibleWidth, roomVisibleHeight = viewportHandler.getRoomVisibleSize(room, viewport)

        local backgroundColor = celesteRender.getRoomBackgroundColor(room, selected)
        local borderColor = celesteRender.getRoomBorderColor(room, selected)

        viewportHandler.drawRelativeTo(roomX, roomY, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(backgroundColor)
                love.graphics.rectangle("fill", 0, 0, width, height)
            end)

            if redrawRoom then
                drawRoomFromBatches(room, viewport, selected)

            else
                if canvas then
                    -- No need to draw the canvas if we can only see the border
                    if roomVisibleWidth > 2 and roomVisibleHeight > 2 then
                        love.graphics.draw(canvas)
                    end
                end
            end

            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(borderColor)
                love.graphics.rectangle("line", 0, 0, width, height)
            end)
        end)
    end
end

-- Iterate over twice
-- Batch draw all selected and unselected fillers
function celesteRender.drawFillers(fillers, viewport, selectedItem, selectedItemType)
    local pr, pb, pg, pa = love.graphics.getColor()

    local multipleSelections = selectedItemType == "table"

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
    end)
end

function celesteRender.drawMap(state)
    if state.map then
        local map = state.map
        local viewport = state.viewport

        if viewport.visible then
            local selectedItem, selectedItemType = state.getSelectedItem()

            celesteRender.drawFillers(map.fillers, viewport, selectedItem, selectedItemType)
            celesteRender.drawRooms(map.rooms, viewport, selectedItem, selectedItemType)
        end
    end
end

return celesteRender