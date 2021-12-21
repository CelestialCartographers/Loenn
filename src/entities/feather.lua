-- TODO - Get this over to a sprite based solution

local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local feather = {}

feather.name = "infiniteStar"
feather.depth = 0
feather.placements = {
    name = "normal",
    data = {
        shielded = false,
        singleUse = false
    }
}

function feather.draw(room, entity, viewport)
    local featherSprite = drawableSprite.fromTexture("objects/flyFeather/idle00", entity)
    local shielded = entity.shielded or false

    if shielded then
        local x, y = entity.x or 0, entity.y or 0

        love.graphics.circle("line", x, y, 12)
    end

    featherSprite:draw()
end

function feather.selection(room, entity)
    if entity.shielded then
        return utils.rectangle(entity.x - 12, entity.y - 12, 24, 24)

    else
        local sprite = drawableSprite.fromTexture("objects/flyFeather/idle00", entity)

        return sprite:getRectangle()
    end
end

return feather