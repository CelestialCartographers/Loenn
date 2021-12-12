local utils = require("utils")
local fakeTilesHelper = require("helpers.fake_tiles")

local movingBlock = {}

movingBlock.name = "finalBossMovingBlock"
movingBlock.depth = 0
movingBlock.nodeLineRenderType = "line"
movingBlock.nodeLimits = {1, 1}
movingBlock.fieldInformation = {
    nodeIndex = {
        fieldType = "integer",
    }
}
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

function movingBlock.nodeRectangle(room, entity, node)
    return utils.rectangle(node.x or 0, node.y or 0, entity.width or 8, entity.height or 8)
end

return movingBlock