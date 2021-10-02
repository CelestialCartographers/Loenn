local fakeTilesHelper = require("helpers.fake_tiles")

local exitBlock = {}

exitBlock.name = "exitBlock"
exitBlock.depth = -13000
exitBlock.placements = {
    name = "exit_block",
    data = {
        tileType = "3",
        playTransitionReveal = false,
        width = 8,
        height = 8
    }
}

exitBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tileType", false, "tilesFg", {1.0, 1.0, 1.0, 0.7})

return exitBlock