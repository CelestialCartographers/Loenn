local drawableSpriteStruct = require("structs.drawable_sprite")
local utils = require("utils")

local flutterbird = {}

local colors = {
    "89FBFF",
    "F0FC6C",
    "F493FF",
    "93BAFF"
}

flutterbird.name = "flutterbird"
flutterbird.depth = -9999
flutterbird.placements = {
    name = "normal"
}

local texture = "scenery/flutterbird/idle00"

function flutterbird.sprite(room, entity)
    utils.setSimpleCoordinateSeed(entity.x, entity.y)

    local colorIndex = math.random(1, #colors)
    local flutterbirdSprite = drawableSpriteStruct.fromTexture(texture, entity)

    flutterbirdSprite:setJustification(0.5, 1.0)
    flutterbirdSprite:setColor(colors[colorIndex])

    return flutterbirdSprite
end

return flutterbird