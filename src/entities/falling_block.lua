local fakeTilesHelper = require("helpers.fake_tiles")

local fallingBlock = {}

fallingBlock.name = "fallingBlock"

function fallingBlock.placements()
    return {
        name = "falling_block",
        data = {
            tiletype = fakeTilesHelper.getPlacementMaterial(),
            climbFall = true,
            behind = false,
            width = 8,
            height = 8
        }
    }
end

fallingBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false)
fallingBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

function fallingBlock.depth(room, entity)
    return entity.behind and 5000 or 0
end

return fallingBlock
