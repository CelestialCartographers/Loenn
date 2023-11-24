local fakeTilesHelper = require("helpers.fake_tiles")

local coverupWall = {}

coverupWall.name = "coverupWall"
coverupWall.depth = -13000

function coverupWall.placements()
    return {
        name = "coverup_wall",
        data = {
            tiletype = fakeTilesHelper.getPlacementMaterial(),
            width = 8,
            height = 8
        }
    }
end

coverupWall.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", true, "tilesFg", {1.0, 1.0, 1.0, 0.7})
coverupWall.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

return coverupWall