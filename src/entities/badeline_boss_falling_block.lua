local fakeTilesHelper = require("fake_tiles_helper")

local fallingBlock = {}

fallingBlock.name = "finalBossFallingBlock"
fallingBlock.depth = 0
fallingBlock.placements = {
    name = "falling_block",
    data = {
        width = 8,
        height = 8
    }
}

fallingBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("G", false)

return fallingBlock