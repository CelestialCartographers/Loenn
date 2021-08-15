local utils = require("utils")
local drawing = require("drawing")
local drawableSprite = require("structs.drawable_sprite")

local bridgeSprite = "scenery/bridge_fixed"

local bridgeFixed = {}

bridgeFixed.name = "bridgeFixed"
bridgeFixed.depth = 0
bridgeFixed.nodeVisibility = "never"
bridgeFixed.placements = {
    name = "bridge_fixed",
    data = {
        width = 32
    }
}

function bridgeFixed.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width = entity.width or 32
    local sprites = {}

    local px = x

    while px < x + width do
        local sprite = drawableSprite.fromTexture(bridgeSprite)

        sprite:setJustification(0.0, 0.0)
        sprite:addPosition(px, y - 8)

        px += sprite.meta.width

        table.insert(sprites, sprite)

    end

    return sprites
end

function bridgeFixed.selection(room, entity)
    local sprite = drawableSprite.fromTexture(bridgeSprite)
    local x, y = entity.x or 0, entity.y or 0

    local width = entity.width or 32
    local selectionWidth = math.ceil(width / sprite.meta.width) * sprite.meta.width

    return utils.rectangle(x, y - 4, selectionWidth, sprite.meta.height)
end

return bridgeFixed