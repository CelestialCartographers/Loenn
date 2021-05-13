local fakeTilesHelper = require("fake_tiles_helper")

local movingBlock = {}

movingBlock.name = "finalBossMovingBlock"
movingBlock.depth = 0
movingBlock.nodeLineRenderType = "line"
movingBlock.nodeLimits = {1, 1}
movingBlock.placements = {
    name = "moving_block",
    data = {
        nodeIndex = 0,
        width = 8,
        height = 8
    }
}

movingBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("G", false)
movingBlock.nodeSprite = fakeTilesHelper.getEntitySpriteFunction("g", false)

return movingBlock