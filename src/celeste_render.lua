local autotiler = require("autotiler")
local spriteMeta = require("sprite_meta")
local drawing = require("drawing")
local tilesUtils = require("tiles")

local tilesetFileFg = "C:/Users/GT/AppData/Local/Ahorn/XML/ForegroundTiles.xml"
local tilesetFileBg = "C:/Users/GT/AppData/Local/Ahorn/XML/BackgroundTiles.xml"

local tilesMetaFg = autotiler.loadTilesetXML(tilesetFileFg)
local tilesMetaBg = autotiler.loadTilesetXML(tilesetFileBg)

local gameplayMeta = "C:/Users/GT/AppData/Local/Ahorn/Sprites/Gameplay.meta"
local gameplayPng = "C:/Users/GT/AppData/Local/Ahorn/Sprites/Gameplay.png"

local gameplayAtlas = spriteMeta.loadSprites(gameplayMeta, gameplayPng)

local function drawTiles(tiles, meta)
    local tilesRaw = tiles.innerText
    local tiles = tilesUtils.convertTileString(tilesRaw)

    local width, height = tiles:size

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

                    local spritesWidth, spritesHeight = spriteMeta.image:getDimensions
                    local quad = love.graphics.newQuad(spriteMeta.x - spriteMeta.offsetX + quadX * 8, spriteMeta.y - spriteMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)

                    love.graphics.draw(spriteMeta.image, quad, x * 8 - 8, y * 8 - 8)
                end
            end
        end
    end
end

local function drawFgTiles(tiles)
    drawTiles(tiles, tilesMetaFg)
end

local function drawBgTiles(tiles)

end

local function drawDecals(decals)
    for i, decal <- decals.__children do
        local texture = drawing.getDecalTexture(decal.texture or "")

        local x = decal.x or 0
        local y = decal.y or 0

        local scaleX = decal.scaleX or 1
        local scaleY = decal.scaleY or 1

        local meta = gameplayAtlas[texture]

        if meta then
            love.graphics.push()

            love.graphics.translate(x, y)
            love.graphics.scale(scaleX, scaleY)
            love.graphics.translate(-meta.offsetX, -meta.offsetY)
            love.graphics.translate(math.floor(-meta.realWidth / 2), math.floor(meta.realHeight / 2))

            drawing.drawSprite(meta, 0, 0)

            love.graphics.pop()
        end
    end
end

local function drawEntities(entities)

end

local function drawTriggers(triggers)

end

local roomDrawingFunctions = {
    entities = drawEntities,
    triggers = drawTriggers,
    fgdecals = drawDecals,
    bgdecals = drawDecals,
    solids = drawFgTiles
}

local function drawRoom(room)
    local roomX = room.x or 0
    local roomY = room.y or 0

    love.graphics.push()

    love.graphics.scale(2, 2)
    love.graphics.translate(roomX, roomY)

    for key, value <- room.__children do
        local name = value.__name
        local func = roomDrawingFunctions[name]

        if func then
            func(value)
        end
    end

    love.graphics.pop()
end

local function drawFiller(filler)

end

local function drawMap(map)
    for i, data <- map.__children[1].__children do
        if data.__name == "levels" then
            for j, room <- data.__children or {} do
                drawRoom(room)
            end

        elseif data.__name == "Filler" then
            for j, filler <- data.__children or {} do
                drawFiller(filler)
            end
        end
    end
end

return {
    drawMap = drawMap,
    drawRoom = drawRoom,
    drawFgTiles = drawFgTiles,
    drawBgTiles = drawBgTiles,
    drawFgDecals = drawFgDecals,
    drawBgDecals = drawBgDecals
}