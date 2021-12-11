local drawableRectangle = require("structs.drawable_rectangle")
local xnaColors = require("consts.xna_colors")
local utils = require("utils")
local connectedEntities = require("helpers.connected_entities")

local waterfallHelper = {}

-- Waterfalls --

local function waterSearchPredicate(entity)
    return entity._name == "water"
end

local function anyCollisions(rectangle, rectangles)
    for _, rect in ipairs(rectangles) do
        if utils.aabbCheck(rect, rectangle) then
            return true
        end
    end

    return false
end

local lightBlue = xnaColors.LightBlue
local waterfallFillColor = {lightBlue[1] * 0.3, lightBlue[2] * 0.3, lightBlue[3] * 0.3, 0.3}
local waterfallBorderColor = {lightBlue[1] * 0.8, lightBlue[2] * 0.8, lightBlue[3] * 0.8, 0.8}

function waterfallHelper.addWaveLineSprite(sprites, entityY, entityHeight, x, y, width, height, color)
    local rectangle = drawableRectangle.fromRectangle("fill", x, y, width, height, color)
    local bottomY = entityY + entityHeight

    if rectangle.y <= bottomY and rectangle.y + rectangle.height >= entityY then
        -- Ajust bottom
        if rectangle.y + rectangle.height > bottomY then
            rectangle.height = bottomY - rectangle.y
        end

        -- Adjust top
        if rectangle.y < entityY then
            rectangle.height += (rectangle.y - entityY)
            rectangle.y = entityY
        end

        if rectangle.height > 0 then
            table.insert(sprites, rectangle:getDrawableSprite())
        end
    end
end

-- Height for the small waterfalls
function waterfallHelper.getWaterfallHeight(room, entity)
    local waterBlocks = utils.filter(waterSearchPredicate, room.entities)
    local waterRectangles = connectedEntities.getEntityRectangles(waterBlocks)

    local x, y = entity.x or 0, entity.y or 0
    local tileX, tileY = math.floor(x / 8) + 1, math.floor(y / 8) + 1

    local roomHeight = room.height
    local wantedHeight = 8 - y % 8

    local tileMatrix = room.tilesFg.matrix

    while wantedHeight < roomHeight - y do
        local rectangle = utils.rectangle(x, y + wantedHeight, 8, 8)

        if anyCollisions(rectangle, waterRectangles) then
            break
        end

        if tileMatrix:get(tileX, tileY + 1, "0") ~= "0" then
            break
        end

        wantedHeight += 8
        tileY += 1
    end

    return wantedHeight
end

function waterfallHelper.getWaterfallSprites(room, entity, fillColor, borderColor)
    fillColor = fillColor or waterfallFillColor
    borderColor = borderColor or waterfallBorderColor

    local x, y = entity.x or 0, entity.y or 0
    local height = waterfallHelper.getWaterfallHeight(room, entity)

    local sprites = {}

    local middleRectangle = drawableRectangle.fromRectangle("fill", x, y, 8, height, fillColor)
    local leftRectangle = drawableRectangle.fromRectangle("fill", x - 1, y, 1, height, borderColor)
    local rightRectangle = drawableRectangle.fromRectangle("fill", x + 8, y, 1, height, borderColor)

    table.insert(sprites, middleRectangle:getDrawableSprite())
    table.insert(sprites, leftRectangle:getDrawableSprite())
    table.insert(sprites, rightRectangle:getDrawableSprite())

    local addWaveLineSprite = waterfallHelper.addWaveLineSprite

    -- Add wave pattern
    for i = 0, height, 21 do
        -- From left to right in the waterfall
        addWaveLineSprite(sprites, y, height, x, y + i + 9, 1, 13, borderColor)
        addWaveLineSprite(sprites, y, height, x + 1, y + i + 11, 1, 8, borderColor)
        addWaveLineSprite(sprites, y, height, x + 6, y + i + 1, 1, 8, borderColor)
        addWaveLineSprite(sprites, y, height, x + 7, y + i - 2, 1, 13, borderColor)
    end

    return sprites
end

function waterfallHelper.getWaterfallRectangle(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local height = waterfallHelper.getWaterfallHeight(room, entity)

    return utils.rectangle(x - 1, y, 10, height)
end

-- Big Waterfalls --

-- Different color depending on layer
-- The background color might be incorrect
local function getBigWaterfallColors(entity)
    local foreground = waterfallHelper.isForeground(entity)

    if foreground then
        local baseColor = xnaColors.LightBlue
        local fillColor = {baseColor[1] * 0.3, baseColor[2] * 0.3, baseColor[3] * 0.3, 0.3}
        local borderColor = {baseColor[1] * 0.8, baseColor[2] * 0.8, baseColor[3] * 0.8, 0.8}

        return fillColor, borderColor

    else
        local fillSuccess, fillR, fillG, fillB = utils.parseHexColor("29a7ea")
        local borderSuccess, borderR, borderG, borderB = utils.parseHexColor("89dbf0")
        local fillColor = {fillR * 0.3, fillB * 0.3, fillG * 0.3, 0.3}
        local borderColor = {borderR * 0.5, borderG * 0.5, borderB * 0.5, 0.5}

        return fillColor, borderColor
    end
end

function waterfallHelper.isForeground(entity)
    return entity.layer == "FG"
end

-- Different gap depending on layer
function waterfallHelper.getBorderOffsetorderOffset(entity)
    local foreground = waterfallHelper.isForeground(entity)

    return foreground and 2 or 3
end

function waterfallHelper.getBigWaterfallSprite(room, entity, fillColor, borderColor)
    if not fillColor or not borderColor then
        local defaultFillColor, defaultBorderColor = getBigWaterfallColors(entity)

        fillColor = fillColor or defaultFillColor
        borderColor = borderColor or defaultBorderColor
    end

    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 16, entity.height or 64

    local borderOffset = waterfallHelper.getBorderOffsetorderOffset(entity)

    local sprites = {}

    local middleRectangle = drawableRectangle.fromRectangle("fill", x, y, width, height, fillColor)
    local leftRectangle = drawableRectangle.fromRectangle("fill", x, y, 2, height, borderColor)
    local rightRectangle = drawableRectangle.fromRectangle("fill", x + width - 2, y, 2, height, borderColor)

    table.insert(sprites, middleRectangle:getDrawableSprite())
    table.insert(sprites, leftRectangle:getDrawableSprite())
    table.insert(sprites, rightRectangle:getDrawableSprite())

    local addWaveLineSprite = waterfallHelper.addWaveLineSprite

    -- Add wave pattern
    for i = 0, height, 21 do
        -- From left to right in the waterfall
        -- Parts connected to side borders
        addWaveLineSprite(sprites, y, height, x + 2, y + i + 9, 1, 12, borderColor)
        addWaveLineSprite(sprites, y, height, x + 3, y + i + 11, 1, 8, borderColor)
        addWaveLineSprite(sprites, y, height, x + width - 4, y + i, 1, 9, borderColor)
        addWaveLineSprite(sprites, y, height, x + width - 3, y + i - 2, 1, 13, borderColor)

        -- Wave on left border
        addWaveLineSprite(sprites, y, height, x + 1 + borderOffset, y + i, 1, 9, borderColor)
        addWaveLineSprite(sprites, y, height, x + 2 + borderOffset, y + i + 9, 1, 2, borderColor)
        addWaveLineSprite(sprites, y, height, x + 2 + borderOffset, y + i + 19, 1, 2, borderColor)
        addWaveLineSprite(sprites, y, height, x + 3 + borderOffset, y + i + 11, 1, 8, borderColor)

        -- Wave on right border
        addWaveLineSprite(sprites, y, height, x + width - 2 - borderOffset, y + i - 10, 1, 8, borderColor)
        addWaveLineSprite(sprites, y, height, x + width - 3 - borderOffset, y + i - 2, 1, 2, borderColor)
        addWaveLineSprite(sprites, y, height, x + width - 3 - borderOffset, y + i + 9, 1, 2, borderColor)
        addWaveLineSprite(sprites, y, height, x + width - 4 - borderOffset, y + i, 1, 9, borderColor)
    end

    return sprites
end

function waterfallHelper.getBigWaterfallRectangle(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 16, entity.height or 64

    return utils.rectangle(x, y, width, height)
end

return waterfallHelper