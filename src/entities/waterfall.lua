local waterfallHelper = require("helpers.waterfalls")

local waterfall = {}

waterfall.name = "waterfall"
waterfall.depth = -9999
waterfall.placements = {
    name = "waterfall"
}

function waterfall.sprite(room, entity)
    return waterfallHelper.getWaterfallSprites(room, entity)
end

waterfall.rectangle = waterfallHelper.getWaterfallRectangle

return waterfall