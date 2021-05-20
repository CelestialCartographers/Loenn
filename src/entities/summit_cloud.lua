local utils = require("utils")
local drawableSprite = require("structs.drawable_sprite")

local summitCloud = {}

-- cloud02 does not exist
local cloudTextures = {
    "scenery/summitclouds/cloud00",
    "scenery/summitclouds/cloud01",
    "scenery/summitclouds/cloud03"
}

summitCloud.name = "summitcloud"
summitCloud.depth = -10550
summitCloud.placements = {
    name = "summit_cloud"
}

function summitCloud.sprite(room, entity)
    utils.setSimpleCoordinateSeed(entity.x, entity.y)

    local texture = cloudTextures[math.random(1, #cloudTextures)]
    local sprite = drawableSprite.fromTexture(texture, entity)
    local scaleX = math.random(0, 1) == 0 and -1 or 1

    sprite:setScale(scaleX, 1)

    return sprite
end

return summitCloud