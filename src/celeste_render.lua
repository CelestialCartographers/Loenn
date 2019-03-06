local autotiler = require("autotiler")
local spriteLoader = require("sprite_loader")
local drawing = require("drawing")
local tilesUtils = require("tiles")
local viewportHandler = require("viewport_handler")
local fileLocations = require("file_locations")
local colors = require("colors")
local tasks = require("task")
local utils = require("utils")

local tilesetFileFg = fileLocations.getResourceDir() .. "/XML/ForegroundTiles.xml"
local tilesetFileBg = fileLocations.getResourceDir() .. "/XML/BackgroundTiles.xml"

local tilesMetaFg = autotiler.loadTilesetXML(tilesetFileFg)
local tilesMetaBg = autotiler.loadTilesetXML(tilesetFileBg)

local gameplayMeta = fileLocations.getResourceDir() .. "/Atlases/Gameplay.meta"
local celesteAtlasFolder = fileLocations.getResourceDir() .. "/Atlases/"

local gameplayAtlas = spriteLoader.loadSpriteAtlas(gameplayMeta, celesteAtlasFolder)

local triggerFontSize = 1

local spriteBatchMode = "static"

local tilesQuadCache = {}

-- Temp
local roomCache = {}

local function getRoomBackgroundColor(room)
    local color = room.c or 0

    if color >= 0 and color < #colors.roomBackgroundColors then
        return colors.roomBackgroundColors[color + 1]

    else
        return colors.roomBackgroundDefault
    end
end

local function getRoomBorderColor(room)
    local color = room.c or 0

    if color >= 0 and color < #colors.roomBorderColors then
        return colors.roomBorderColors[color + 1]

    else
        return colors.roomBorderDefault
    end
end

local function getTilesBatch(tiles, meta)
    local tilesRaw = tiles.innerText or ""
    local tiles = tilesUtils.convertTileString(tilesRaw)

    local width, height = tiles:size
    local spriteBatch = love.graphics.newSpriteBatch(gameplayAtlas._imageMeta[1].image, 1024, spriteBatchMode)

    -- Slicing currently doesnt allow default values, just ignore the literal edgecases
    for x = 1, width do
        for y = 1, height do
            local tile = tiles[x, y]

            if tile ~= "0" then
                local quads, sprites = autotiler.getQuads(x, y, tiles, meta)
                local quadCount = quads.len and quads:len or #quads
                local texture = meta.paths[tile] or ""
                local spriteMeta = gameplayAtlas[texture]
                local spritesWidth, spritesHeight = spriteMeta.image:getDimensions

                if spriteMeta and quadCount > 0 then
                    -- TODO - Cache quad creation
                    local randQuad = quads[math.random(1, quadCount)]
                    local quadX, quadY = randQuad[1], randQuad[2]

                    tilesQuadCache[tile] = tilesQuadCache[tile] or table.filled(false, {6, 15})
                    local quadCache = tilesQuadCache[tile]
                    
                    if not tilesQuadCache[quadX + 1, quadY + 1] then
                        quadCache[quadX + 1, quadY + 1] = love.graphics.newQuad(spriteMeta.x - spriteMeta.offsetX + quadX * 8, spriteMeta.y - spriteMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)
                    end

                    spriteBatch:add(quadCache[quadX + 1, quadY + 1], x * 8 - 8, y * 8 - 8)
                end
            end

            coroutine.yield()
        end
    end

    coroutine.yield(spriteBatch)
end

local function drawTilesFg(room, tiles)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].fgTiles = roomCache[room.name].fgTiles or tasks.newTask(function() getTilesBatch(tiles, tilesMetaFg) end)

    local batch = roomCache[room.name].fgTiles.result

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

local function drawTilesBg(room, tiles)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].bgTiles = roomCache[room.name].bgTiles or tasks.newTask(function() getTilesBatch(tiles, tilesMetaBg) end)

    local batch = roomCache[room.name].bgTiles.result

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

local function getDecalsBatch(decals)
    local decals = (decals or {}).__children or {}
    local decalCount = decals.len and decals:len or #decals
    local spriteBatch = love.graphics.newSpriteBatch(gameplayAtlas._imageMeta[1].image, math.max(decalCount, 1), spriteBatchMode)

    for i, decal <- decals do
        local texture = drawing.getDecalTexture(decal.texture or "")

        local x = decal.x or 0
        local y = decal.y or 0

        local scaleX = decal.scaleX or 1
        local scaleY = decal.scaleY or 1

        local meta = gameplayAtlas[texture]

        if meta then
            spriteBatch:add(
                meta.quad,
                x - meta.offsetX * scaleX - math.floor(meta.realWidth / 2) * scaleX,
                y - meta.offsetY * scaleY - math.floor(meta.realHeight / 2) * scaleY,
                0,
                scaleX,
                scaleY
            )
        end

        coroutine.yield()
    end

    coroutine.yield(spriteBatch)
end

local function drawDecalsFg(room, decals)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].fgDecals = roomCache[room.name].fgDecals or tasks.newTask(function() getDecalsBatch(decals) end)

    local batch = roomCache[room.name].fgDecals.result

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

local function drawDecalsBg(room, decals)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].bgDecals = roomCache[room.name].bgDecals or tasks.newTask(function() getDecalsBatch(decals) end)

    local batch = roomCache[room.name].bgDecals.result

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

local function drawEntities(room, entities)
    love.graphics.setColor(colors.entityMissingColor)

    for i, entity <- entities.__children or {} do
        local name = entity.__name

        local x = entity.x or 0
        local y = entity.y or 0
        
        love.graphics.rectangle("fill", x - 1, y - 1, 3, 3)
    end

    love.graphics.setColor(colors.default)
end

local function drawTriggers(room, triggers)
    local font = love.graphics.getFont()

    for i, trigger <- triggers.__children or {} do
        local name = trigger.__name
        local displayName = utils.humanizeVariableName(name)

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        love.graphics.setColor(colors.triggerColor)
        
        love.graphics.rectangle("line", x, y, width, height)
        love.graphics.rectangle("fill", x, y, width, height)

        love.graphics.setColor(colors.triggerTextColor)

        local longest, lines = font:getWrap(displayName, width)
        local textHeight = #lines * (font:getHeight() * font:getLineHeight())

        local offsetX = 0
        local offsetY = (textHeight - height) / 2

        love.graphics.printf(displayName, x, y, width, "center", 0, triggerFontSize, triggerFontSize, offsetX, offsetY)
    end

    love.graphics.setColor(colors.default)
end

local roomDrawingFunctions = {
    {"Background Tiles", "bg", drawTilesBg},
    {"Background Decals", "bgdecals", drawDecalsBg},
    {"Entities", "entities", drawEntities},
    {"Foreground Tiles", "solids", drawTilesFg},
    {"Foreground Decals", "fgdecals", drawDecalsFg},
    {"Triggers", "triggers", drawTriggers}
}

local function drawRoom(room, viewport)
    local roomX = room.x or 0
    local roomY = room.y or 0

    local width = room.width or 40 * 8
    local height = room.height or 23 * 8

    local backgroundColor = getRoomBackgroundColor(room)
    local borderColor = getRoomBorderColor(room)

    love.graphics.push()

    love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
    love.graphics.scale(viewport.scale, viewport.scale)
    love.graphics.translate(roomX, roomY)

    love.graphics.setColor(backgroundColor)
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.setColor(borderColor)
    love.graphics.rectangle("line", 0, 0, width, height)

    love.graphics.setColor(colors.default)

    local roomData = {}

    for key, value <- room.__children do
        roomData[value.__name] = value
    end

    for i, data <- roomDrawingFunctions do
        local description, key, func = unpack(data)
        local value = roomData[key]
        
        if value then
            func(room, value)
        end
    end

    love.graphics.pop()
end

local function drawFiller(filler, viewport)
    love.graphics.push()

    local fillerX = filler.x * 8
    local fillerY = filler.y * 8

    local width = filler.w * 8
    local height = filler.h * 8

    love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
    love.graphics.scale(viewport.scale, viewport.scale)
    love.graphics.translate(fillerX, fillerY)

    love.graphics.setColor(colors.fillerColor)
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.setColor(colors.default)

    love.graphics.pop()
end

local function drawMap(map)
    if map.result then
        local map = map.result
        local viewport = viewportHandler.getViewport()

        if viewport.visible then
            for i, data <- map.__children[1].__children do
                if data.__name == "levels" then
                    for j, room <- data.__children or {} do
                        if viewportHandler.roomVisible(room, viewport) then
                            drawRoom(room, viewport)
                        end
                    end

                elseif data.__name == "Filler" then
                    for j, filler <- data.__children or {} do
                        -- TODO - Don't draw out of view fillers
                        -- ... Even though checking if they are out of view is probably more expensive than drawing it
                        drawFiller(filler, viewport)
                    end
                end
            end

        else
            -- TODO - Test and commit if it works
            print("Not visible... Waiting 200ms...")
            love.timer.sleep(0.2)
        end
    end
end

return {
    drawMap = drawMap,
    drawRoom = drawRoom,
    drawTilesFg = drawTilesFg,
    drawTilesBg = drawTilesBg,
    drawDecalsFg = drawDecalsFg,
    drawDecalsBg = drawDecalsBg
}