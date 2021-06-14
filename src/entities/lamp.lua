local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local lamp = {}

lamp.name = "lamp"
lamp.depth = 5
lamp.justification = {0.25, 0.25}
lamp.placements = {
    {
        name = "normal",
        data = {
            broken = false
        }
    },
    {
        name = "broken",
        data = {
            broken = true
        }
    }
}

local texture = "scenery/lamp"

function lamp.sprite(room, entity)
    local broken = entity.broken
    local sprite = drawableSprite.fromTexture(texture, entity)

    -- Image is split in half, width is the width of one lamp pole
    local width = math.floor(sprite.meta.width / 2)
    local halfWidth = math.floor(width / 2)
    local height = sprite.meta.height

    sprite:setJustification(0.0, 0.0)
    sprite:addPosition(-halfWidth, -height)
    sprite:setOffset(0, 0)
    sprite:useRelativeQuad(broken and width or 0, 0, width, height)

    return sprite
end

function lamp.selection(room, entity)
    local sprite = drawableSprite.fromTexture(texture, entity)

    local width = math.floor(sprite.meta.width / 2)
    local halfWidth = math.floor(width / 2)
    local height = sprite.meta.height

    return utils.rectangle(entity.x - halfWidth, entity.y - height, width, height)
end

return lamp
