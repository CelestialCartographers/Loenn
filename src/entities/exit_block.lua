local fakeTilesHelper = require("helpers.fake_tiles")

local exitBlock = {}

exitBlock.name = "exitBlock"
exitBlock.depth = -13000

function exitBlock.placements()
    return {
        name = "exit_block",
        data = {
            tileType = fakeTilesHelper.getPlacementMaterial(),
            playTransitionReveal = false,
            width = 8,
            height = 8
        }
    }
end

exitBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tileType", false, "tilesFg", {1.0, 1.0, 1.0, 0.7})
exitBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tileType")

return exitBlock