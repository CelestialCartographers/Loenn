local autotiler = require("autotiler")
local spriteLoader = require("sprite_loader")
local drawing = require("drawing")
local viewportHandler = require("viewport_handler")
local fileLocations = require("file_locations")
local colors = require("colors")
local tasks = require("task")
local utils = require("utils")
local atlases = require("atlases")
local entityHandler = require("entities")

local tilesetFileFg = fileLocations.getResourceDir() .. "/XML/ForegroundTiles.xml"
local tilesetFileBg = fileLocations.getResourceDir() .. "/XML/BackgroundTiles.xml"

local tilesMetaFg = autotiler.loadTilesetXML(tilesetFileFg)
local tilesMetaBg = autotiler.loadTilesetXML(tilesetFileBg)

local triggerFontSize = 1

local spriteBatchMode = "static"

local tilesQuadCache = {}

local celesteRender = {}

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

local function getOrCacheTileQuad(tile, spriteMeta, quad, fg)
    tilesQuadCache[tile] = tilesQuadCache[tile] or {}
    tilesQuadCache[tile][fg] = tilesQuadCache[tile][fg] or table.filled(false, {6, 15})
    local tilesQuadCache = tilesQuadCache[tile][fg]
    local quadX, quadY = quad[1], quad[2]
    
    if not tilesQuadCache[quadX + 1, quadY + 1] then
        local spritesWidth, spritesHeight = spriteMeta.image:getDimensions

        tilesQuadCache[quadX + 1, quadY + 1] = love.graphics.newQuad(spriteMeta.x - spriteMeta.offsetX + quadX * 8, spriteMeta.y - spriteMeta.offsetY + quadY * 8, 8, 8, spritesWidth, spritesHeight)
    end

    return tilesQuadCache[quadX + 1, quadY + 1]
end

function celesteRender.getTilesBatch(tiles, meta, fg)
    local tiles = tiles.matrix

    local width, height = tiles:size
    local spriteBatch = love.graphics.newSpriteBatch(atlases.gameplay._imageMeta[1].image, 1024, spriteBatchMode)

    for x = 1, width do
        for y = 1, height do
            local tile = tiles[x, y]

            if tile ~= "0" then
                local quads, sprites = autotiler.getQuads(x, y, tiles, meta)
                local quadCount = quads.len and quads:len or #quads
                local texture = meta.paths[tile] or ""
                local spriteMeta = atlases.gameplay[texture]

                if spriteMeta and quadCount > 0 then
                    local randQuad = quads[math.random(1, quadCount)]
                    local drawQuad = getOrCacheTileQuad(tile, spriteMeta, randQuad, fg)

                    spriteBatch:add(drawQuad, x * 8 - 8, y * 8 - 8)
                end
            end
        end

        coroutine.yield()
    end

    coroutine.yield(spriteBatch)
end

local function getRoomTileBatch(room, tiles, fg)
    local key = fg and "fgTiles" or "bgTiles"
    local meta = fg and tilesMetaFg or tilesMetaBg

    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name][key] = roomCache[room.name][key] or tasks.newTask(
        (-> celesteRender.getTilesBatch(tiles, meta, fg)),
        (task -> print(string.format("Batching '%s' in '%s' took %s ms", key, room.name, task.timeTotal * 1000)))
    )

    return roomCache[room.name][key].result
end

function celesteRender.drawTilesFg(room, tiles)
    local batch = getRoomTileBatch(room, tiles, true)

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

function celesteRender.drawTilesBg(room, tiles)
    local batch = getRoomTileBatch(room, tiles, false)

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

function celesteRender.getDecalsBatch(decals)
    local spriteBatch = love.graphics.newSpriteBatch(atlases.gameplay._imageMeta[1].image, math.max(decals:len, 1), spriteBatchMode)

    for i, decal <- decals do
        local texture = decal.texture

        local x = decal.x or 0
        local y = decal.y or 0

        local scaleX = decal.scaleX or 1
        local scaleY = decal.scaleY or 1

        local meta = atlases.gameplay[texture]

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

        if i % 10 == 0 then
            coroutine.yield()
        end
    end

    coroutine.yield(spriteBatch)
end

local function getRoomDecalsBatch(room, decals, fg)
    local key = fg and "fgDecals" or "bgDecals"

    roomCache[room.name] = roomCache[room.name] or {}
    roomCache[room.name][key] = roomCache[room.name][key] or tasks.newTask(
        (-> celesteRender.getDecalsBatch(decals)),
        (task -> print(string.format("Batching '%s' in '%s' took %s ms", key, room.name, task.timeTotal * 1000)))
    )

    return roomCache[room.name][key].result
end

function celesteRender.drawDecalsFg(room, decals)
    local batch = getRoomDecalsBatch(room, decals, true)

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

function celesteRender.drawDecalsBg(room, decals)
    local batch = getRoomDecalsBatch(room, decals, false)

    if batch then
        love.graphics.draw(batch, 0, 0)
    end
end

local function getEntityDrawCalls(room, entities, viewport, registeredEntities)
    local registeredEntities = registeredEntities or entityHandler.registeredEntities

    local res = $()

    for i, entity <- entities do
        local name = entity._name
        local handler = registeredEntities[name]

        if handler then
            local defaultDepth = type(handler.depth) == "function" and handler.depth(room, entity, viewport) or handler.depth or 0

            if handler.sprite then
                local sprites = handler.sprite(room, entity, viewport)

                if sprites then
                    local spriteCount = sprites.len and sprites:len or #sprites
                    if spriteCount == 0 and sprites.meta then
                        sprites.depth = sprites.depth or defaultDepth
                        res += sprites

                    else
                        for i, sprite <- sprites do
                            if sprite.meta then
                                sprite.depth = sprite.depth or defaultDepth
                                res += sprite
                            end
                        end
                    end
                end
            end

            if handler.draw then
                res += {
                    func = handler.draw,
                    depth = defaultDepth,
                    room = room,
                    entity = entity
                }
            end
        end
    end

    return res
end

-- TODO - Add more advanced rendering support
function celesteRender.drawEntities(room, entities, viewport, registeredEntities)
    local registeredEntities = registeredEntities or entityHandler.registeredEntities

    local drawables = getEntityDrawCalls(room, entities, viewport, registeredEntities)
    drawables := sortby(d -> d.depth or 0)
    drawables := reverse

    for i, drawable <- drawables do
        if drawable.func then
            drawable.func(drawable.room, drawable.entity)

        else
            local color = drawable.color
            local offsetX = drawable.jx * drawable.meta.realWidth + drawable.meta.offsetX
            local offsetY = drawable.jy * drawable.meta.realHeight + drawable.meta.offsetY

            if color then
                love.graphics.setColor(color)
            end

            love.graphics.draw(drawable.meta.image, drawable.meta.quad, drawable.x, drawable.y, drawable.r, drawable.sx, drawable.sy, offsetX, offsetY)

            if color then
                love.graphics.setColor(colors.default)
            end
        end
    end
end

function celesteRender.drawTriggers(room, triggers)
    local font = love.graphics.getFont()

    for i, trigger <- triggers do
        local name = trigger._name or ""
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
    {"Background Tiles", "tiles_bg", celesteRender.drawTilesBg},
    {"Background Decals", "decals_bg", celesteRender.drawDecalsBg},
    {"Entities", "entities", celesteRender.drawEntities},
    {"Foreground Tiles", "tiles_fg", celesteRender.drawTilesFg},
    {"Foreground Decals", "decals_fg", celesteRender.drawDecalsFg},
    {"Triggers", "triggers", celesteRender.drawTriggers}
}

function celesteRender.drawRoom(room, viewport)
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

    for i, data <- roomDrawingFunctions do
        local description, key, func = unpack(data)
        local value = room[key]

        if value then
            func(room, value, viewport)
        end
    end

    love.graphics.pop()
end

function celesteRender.drawFiller(filler, viewport)
    local x = filler.x * 8
    local y = filler.y * 8

    local width = filler.width * 8
    local height = filler.height * 8

    love.graphics.push()

    love.graphics.translate(math.floor(-viewport.x), math.floor(-viewport.y))
    love.graphics.scale(viewport.scale, viewport.scale)
    love.graphics.translate(x, y)

    love.graphics.setColor(colors.fillerColor)
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.setColor(colors.default)

    love.graphics.pop()
end

function celesteRender.drawMap(map)
    if map.result then
        local map = map.result
        local viewport = viewportHandler.viewport

        if viewport.visible then
            for i, room <- map.rooms do
                if viewportHandler.roomVisible(room, viewport) then
                    celesteRender.drawRoom(room, viewport)
                end
            end

            for i, filler <- map.fillers do
                -- TODO - Don't draw out of view fillers
                -- ... Even though checking if they are out of view is probably more expensive than drawing it
                celesteRender.drawFiller(filler, viewport)
            end
        end
    end
end

return celesteRender