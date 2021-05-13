local fakeTilesHelper = require("fake_tiles_helper")

local dashBlock = {}

dashBlock.name = "dashBlock"
dashBlock.depth = 0
dashBlock.placements = {
    name = "dash_block",
    data = {
        tiletype = "3",
        blendin = false,
        permanent = true,
        width = 8,
        height = 8
    }
}

dashBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", "blendin")

return dashBlock