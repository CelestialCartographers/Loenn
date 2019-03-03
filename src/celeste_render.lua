local autotiler = require("autotiler")
local spriteMeta = require("sprite_meta")
local drawing = require("drawing")
local tilesUtils = require("tiles")
local viewportHandler = require("viewport_handler")
local fileLocations = require("file_locations")

local tilesetFileFg = fileLocations.getResourceDir() .. "/XML/ForegroundTiles.xml"
local tilesetFileBg = fileLocations.getResourceDir() .. "/XML/BackgroundTiles.xml"

local tilesMetaFg = autotiler.loadTilesetXML(tilesetFileFg)
local tilesMetaBg = autotiler.loadTilesetXML(tilesetFileBg)

local gameplayMeta = fileLocations.getResourceDir() .. "/Sprites/Gameplay.meta"
local gameplayPng = fileLocations.getResourceDir() .. "/Sprites/Gameplay.png"

local gameplayAtlas = spriteMeta.loadSprites(gameplayMeta, gameplayPng)

local triggerFontSize = 1

-- Temptf 
local roomCache = {}

local function getTilesBatch(tiles, meta)
    local tilesRaw = tiles.innerText or ""
    local tiles = tilesUtils.convertTileString(tilesRaw)

    local width, height = tiles:size

    local spriteBatch = love.graphics.newSpriteBatch(gameplayAtlas._image)

    -- Slicing currently doesnt allow default values, just ignore the literal edgecases
    for x = 2, width - 1 do
        for y = 2, height - 1 do
            local tile = tiles[x, y]

            if tile ~= "0" then
                local quads, sprites = autotiler.getQuads(x, y, tiles, meta)
                local quadCount = quads.len and quads:len or #quads
                local texture = meta.paths[tile] or ""
                local spriteMeta = gameplayAtlas[texture]

                if spriteMeta and quadCount > 0 then
                    -- Cache quad creation
                    local randQuad = quads[math.random(1, quadCount)]
                    local quadX, quadY = randQuad[1], randQuad[2]

                    local spritesWidth, spritesHeight = gameplayAtlas._width, gameplayAtlas._height
                    local quad = love.graphics.newQuad(spriteMeta.x - spriteMeta.offsetX + quadX * 8, spriteMeta.y - spriteMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)

                    spriteBatch:add(quad, x * 8 - 8, y * 8 - 8)
                end
            end
        end
    end

    return spriteBatch
end

local function drawTilesFg(room, tiles)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].fgTiles = roomCache[room.name].fgTiles or getTilesBatch(tiles, tilesMetaFg)

    local batch = roomCache[room.name].fgTiles

    love.graphics.draw(batch, 0, 0)
end

local function drawTilesBg(room, tiles)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].bgTiles = roomCache[room.name].bgTiles or getTilesBatch(tiles, tilesMetaBg)

    local batch = roomCache[room.name].bgTiles

    love.graphics.draw(batch, 0, 0)
end

local function getDecalsBatch(decals)
    local decals = decals or {}
    local spriteBatch = love.graphics.newSpriteBatch(gameplayAtlas._image)

    for i, decal <- decals.__children or {} do
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
    end

    return spriteBatch
end

local function drawDecalsFg(room, decals)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].fgDecals = roomCache[room.name].fgDecals or getDecalsBatch(decals)

    local batch = roomCache[room.name].fgDecals

    love.graphics.draw(batch, 0, 0)
end

local function drawDecalsBg(room, decals)
    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name].bgDecals = roomCache[room.name].bgDecals or getDecalsBatch(decals)

    local batch = roomCache[room.name].bgDecals

    love.graphics.draw(batch, 0, 0)
end

local function drawEntities(room, entities)
    -- Heh its Hex for "Cru"
    love.graphics.setColor(47, 114, 117, 0.3)

    for i, entity <- entities.__children or {} do
        local name = entity.__name

        local x = entity.x or 0
        local y = entity.y or 0
        
        love.graphics.rectangle("fill", x - 1, y - 1, 3, 3)
    end

    love.graphics.setColor(255, 255, 255, 1.0)
end

local function drawTriggers(room, triggers)
    for i, trigger <- triggers.__children or {} do
        local name = trigger.__name

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        love.graphics.setColor(47, 114, 117, 0.3)
        
        love.graphics.rectangle("line", x, y, width, height)
        love.graphics.rectangle("fill", x, y, width, height)

        love.graphics.setColor(255, 255, 255, 1.0)

        -- TODO - Center properly, split on PascalCase -> Pascal Case etc
        love.graphics.printf(name, x, y + height / 2, width, "center", 0, triggerFontSize, triggerFontSize)
    end
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

    love.graphics.push()

    love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
    love.graphics.scale(viewport.scale, viewport.scale)
    love.graphics.translate(roomX, roomY)

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

local function drawFiller(filler)

end

local function drawMap(map)
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
                    drawFiller(filler, viewport)
                end
            end
        end

    else
        print("Not visible... Waiting 200ms...")
        love.timer.sleep(0.2)
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