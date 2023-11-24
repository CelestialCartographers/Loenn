local fakeTilesHelper = require("helpers.fake_tiles")

local fakeBlock = {}

fakeBlock.name = "fakeBlock"
fakeBlock.depth = -13000

function fakeBlock.placements()
    return {
        name = "fake_block",
        data = {
            tiletype = fakeTilesHelper.getPlacementMaterial(),
            playTransitionReveal = false,
            width = 8,
            height = 8
        }
    }
end

fakeBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false, "tilesFg", {1.0, 1.0, 1.0, 0.7})
fakeBlock.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

return fakeBlock