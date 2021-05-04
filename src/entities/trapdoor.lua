local drawableRectangle = require("structs.drawable_rectangle")

local trapdoor = {}

trapdoor.name = "trapdoor"
trapdoor.depth = 8999
trapdoor.placements = {
    name = "trapdoor"
}

local color = {22 / 255, 27 / 255, 48 / 255, 1.0}

function trapdoor.sprite(room, entity)
    return drawableRectangle.fromRectangle("fill", color, entity.x, entity.y + 6, 24, 4)
end

return trapdoor