local fakeTilesHelper = require("fake_tiles_helper")

local fakeBlock = {}

fakeBlock.name = "fakeBlock"
fakeBlock.depth = -13000
fakeBlock.placements = {
    name = "fake_block",
    data = {
        tiletype = "3",
        playTransitionReveal = false,
        width = 8,
        height = 8
    }
}

fakeBlock.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", false, "tilesFg", {1.0, 1.0, 1.0, 0.7})

return fakeBlock