local fakeTilesHelper = require("helpers.fake_tiles")
local utils = require("utils")

local introCrusher = {}

introCrusher.name = "introCrusher"
introCrusher.depth = 0
introCrusher.nodeLineRenderType = "line"
introCrusher.nodeLimits = {1, 1}
introCrusher.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")
introCrusher.placements = {
    name = "intro_crusher",
    data = {
        tiletype = "3",
        flags = "1,0b",
        width = 8,
        height = 8
    }
}

introCrusher.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false)
introCrusher.nodeSprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false)

function introCrusher.nodeRectangle(room, entity, node)
    return utils.rectangle(node.x or 0, node.y or 0, entity.width or 8, entity.height or 8)
end

return introCrusher