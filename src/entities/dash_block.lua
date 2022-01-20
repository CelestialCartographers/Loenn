local fakeTilesHelper = require("helpers.fake_tiles")

local dashBlock = {}

dashBlock.name = "dashBlock"
dashBlock.depth = 0
dashBlock.placements = {
    name = "dash_block",
    data = {
        tiletype = "3",
        blendin = true,
        canDash = true,
        permanent = true,
        width = 8,
        height = 8
    }
}

dashBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", "blendin")
dashBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

return dashBlock