local fakeTilesHelper = require("helpers.fake_tiles")

local coverupWall = {}

coverupWall.name = "coverupWall"
coverupWall.depth = -13000
coverupWall.placements = {
    name = "coverup_wall",
    data = {
        tiletype = "3",
        width = 8,
        height = 8
    }
}

coverupWall.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", true, "tilesFg", {1.0, 1.0, 1.0, 0.7})

return coverupWall