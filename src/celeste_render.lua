local autotiler = require("autotiler")
local spriteMeta = require("sprite_meta")
local drawing = require("drawing")
local tilesUtils = require("tiles")
local viewportHandler = require("viewport_handler")

local tilesetFileFg = "C:/Users/GT/AppData/Local/Ahorn/XML/ForegroundTiles.xml"
local tilesetFileBg = "C:/Users/GT/AppData/Local/Ahorn/XML/BackgroundTiles.xml"

local tilesMetaFg = autotiler.loadTilesetXML(tilesetFileFg)
local tilesMetaBg = autotiler.loadTilesetXML(tilesetFileBg)

local gameplayMeta = "C:/Users/GT/AppData/Local/Ahorn/Sprites/Gameplay.meta"
local gameplayPng = "C:/Users/GT/AppData/Local/Ahorn/Sprites/Gameplay.png"

local gameplayAtlas = spriteMeta.loadSprites(gameplayMeta, gameplayPng)

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

-- Seems to be wrong now, woops.
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
            print(texture, x, y, scaleX, scaleY, meta.x, meta.y, meta.offsetX, meta.offsetY, meta.width, meta.height, meta.quad:getViewport)

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

end

local function drawTriggers(room, triggers)

end

local roomDrawingFunctions = {
    {"BGTiles", "bg", drawTilesBg},
    {"BGDecals", "bgdecals", drawDecalsBg},
    {"Entities", "entities", drawEntities},
    {"FGTiles", "solids", drawTilesFg},
    {"FGDecals", "fgdecals", drawDecalsFg}
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
end

return {
    drawMap = drawMap,
    drawRoom = drawRoom,
    drawTilesFg = drawTilesFg,
    drawTilesBg = drawTilesBg,
    drawDecalsFg = drawDecalsFg,
    drawDecalsBg = drawDecalsBg
}