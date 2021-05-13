local fakeTilesHelper = require("fake_tiles_helper")

local conditionBlock = {}

conditionBlock.name = "conditionBlock"
conditionBlock.depth = -13000
conditionBlock.placements = {
    name = "condition_block",
    data = {
        tileType = "3",
        condition = "Key",
        conditionID = "1:1",
        width = 8,
        height = 8
    }
}

conditionBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tileType", "blendin", "tilesFg", {1.0, 1.0, 1.0, 0.7})

return conditionBlock