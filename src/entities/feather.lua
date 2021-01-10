local drawableSpriteStruct = require("structs.drawable_sprite")

local feather = {}

feather.name = "infiniteStar"
feather.depth = 0
feather.placements = {
    name = "feather"
}

function feather.draw(room, entity, viewport)
    local featherSprite = drawableSpriteStruct.spriteFromTexture("objects/flyFeather/idle00", entity)
    local shielded = entity.shielded or false

    if shielded then
        local x, y = entity.x or 0, entity.y or 0

        love.graphics.circle("line", x, y, 12)
    end

    featherSprite:draw()
end

return feather