local drawableRectangle = require("structs.drawable_rectangle")
local xnaColors = require("consts.xna_colors")
local utils = require("utils")
local connectedEntities = require("helpers.connected_entities")
local waterfallHelper = require("helpers.waterfalls")

local bigWaterfall = {}

bigWaterfall.name = "bigWaterfall"
bigWaterfall.minimumSize = {16, 16}
bigWaterfall.placements = {
    {
        name = "foreground",
        data = {
            width = 16,
            height = 16,
            layer = "FG"
        }
    },
    {
        name = "background",
        data = {
            width = 16,
            height = 16,
            layer = "BG"
        }
    }
}

local function isForeground(entity)
    return entity.layer == "FG"
end

-- Different color depending on layer
-- The background color might be incorrect
local function getColors(entity)
    local foreground = isForeground(entity)

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

-- Different gap depending on layer
local function getBorderOffsetorderOffset(entity)
    local foreground = isForeground(entity)

    return foreground and 2 or 3
end

function bigWaterfall.depth(room, entity)
    local foreground = entity.layer == "FG"

    return foreground and -49900 or 10010
end

function bigWaterfall.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 16, entity.height or 64

    local fillColor, borderColor = getColors(entity)
    local borderOffset = getBorderOffsetorderOffset(entity)

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

function bigWaterfall.rectangle(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 16, entity.height or 64

    return utils.rectangle(x, y, width, height)
end

return bigWaterfall