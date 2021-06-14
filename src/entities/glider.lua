local drawableSprite = require("structs.drawable_sprite")
local drawableLine = require("structs.drawable_line")
local drawing = require("drawing")

local glider = {}

glider.name = "glider"
glider.depth = -5
glider.placements = {
    {
        name = "normal",
        data = {
            tutorial = false,
            bubble = false
        }
    },
    {
        name = "floating",
        data = {
            tutorial = true,
            bubble = true
        }
    }
}

local texture = "objects/glider/idle0"

function glider.sprite(room, entity)
    local bubble = entity.bubble

    if entity.bubble then
        local x, y = entity.x or 0, entity.y or 0
        local points = drawing.getSimpleCurve({x - 11, y - 1}, {x + 11, y - 1}, {x - 0, y - 6})
        local lineSprites = drawableLine.fromPoints(points):getDrawableSprite()
        local jellySprite = drawableSprite.fromTexture(texture, entity)

        table.insert(lineSprites, 1, jellySprite)

        return lineSprites

    else
        return drawableSprite.fromTexture(texture, entity)
    end
end

return glider