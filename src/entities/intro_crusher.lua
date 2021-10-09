local fakeTilesHelper = require("helpers.fake_tiles")

local introCrusher = {}

introCrusher.name = "introCrusher"
introCrusher.depth = 0
introCrusher.nodeLineRenderType = "line"
introCrusher.nodeLimits = {1, 1}
introCrusher.placements = {
    name = "intro_crusher",
    data = {
        tiletype = "3",
        flags = "1, 0b",
        width = 8,
        height = 8
    }
}

introCrusher.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false)

return introCrusher