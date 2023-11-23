local fakeTilesHelper = require("helpers.fake_tiles")

local crumbleWall = {}

crumbleWall.name = "crumbleWallOnRumble"

function crumbleWall.placements()
    return {
        name = "crumble_wall",
        data = {
            tiletype = fakeTilesHelper.getPlacementMaterial("m"),
            blendin = true,
            permanent = false,
            width = 8,
            height = 8
        }
    }
end

crumbleWall.sprite = fakeTilesHelper.getEntitySpriteFunction("tiletype", "blendin")
crumbleWall.fieldInformation = fakeTilesHelper.getFieldInformation("tiletype")

function crumbleWall.depth(room, entity)
    return entity.blendin and -10501 or -12999
end

return crumbleWall