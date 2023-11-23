local fakeTilesHelper = require("helpers.fake_tiles")

local conditionBlock = {}

conditionBlock.name = "conditionBlock"
conditionBlock.depth = -13000
function conditionBlock.placements()
    return {
        name = "condition_block",
        data = {
            tileType = fakeTilesHelper.getPlacementMaterial(),
            condition = "Key",
            conditionID = "1:1",
            width = 8,
            height = 8
        }
    }
end

conditionBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tileType", "blendin", "tilesFg", {1.0, 1.0, 1.0, 0.7})
conditionBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tileType")

return conditionBlock