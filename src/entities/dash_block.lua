local fakeTilesHelper = require("helpers.fake_tiles")

local dashBlock = {}

dashBlock.name = "dashBlock"
dashBlock.depth = 0

function dashBlock.placements()
    return {
        name = "dash_block",
        data = {
            tiletype = fakeTilesHelper.getPlacementMaterial(),
            blendin = true,
            canDash = true,
            permanent = true,
            width = 8,
            height = 8
        }
    }
end

dashBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", "blendin")
dashBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

return dashBlock