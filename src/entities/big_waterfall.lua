local drawableRectangle = require("structs.drawable_rectangle")
local xnaColors = require("consts.xna_colors")
local utils = require("utils")
local waterfallHelper = require("helpers.waterfalls")

local bigWaterfall = {}

bigWaterfall.name = "bigWaterfall"
bigWaterfall.warnBelowSize = {16, 16}
bigWaterfall.fieldInformation = {
    layer = {
        options = {"FG", "BG"},
        editable = false
    }
}
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

function bigWaterfall.depth(room, entity)
    local foreground = waterfallHelper.isForeground(entity)

    return foreground and -49900 or 10010
end

function bigWaterfall.sprite(room, entity)
    return waterfallHelper.getBigWaterfallSprite(room, entity)
end

bigWaterfall.rectangle = waterfallHelper.getBigWaterfallRectangle

return bigWaterfall