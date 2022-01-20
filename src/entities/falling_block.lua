local fakeTilesHelper = require("helpers.fake_tiles")

local fallingBlock = {}

fallingBlock.name = "fallingBlock"
fallingBlock.placements = {
    name = "falling_block",
    data = {
        tiletype = "3",
        climbFall = true,
        behind = false,
        width = 8,
        height = 8
    }
}

fallingBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false)
fallingBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

function fallingBlock.depth(room, entity)
    return entity.behind and 5000 or 0
end

return fallingBlock