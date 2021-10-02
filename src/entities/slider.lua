local drawableSpriteStruct = require("structs.drawable_sprite")
local drawing = require("utils.drawing")
local utils = require("utils")

local slider = {}

slider.name = "slider"
slider.depth = 0
slider.placements = {
    name = "clockwise",
    data = {
        clockwise = true,
        surface = "Floor"
    }
}

function slider.draw(room, entity, viewport)
    drawing.callKeepOriginalColor(function()
        local x, y = entity.x or 0, entity.y or 0

        love.graphics.setColor(1.0, 0.0, 0.0)
        love.graphics.circle("line", x, y, 12)
    end)
end

function slider.selection(room, entity)
    return utils.rectangle(entity.x - 12, entity.y - 12, 24, 24)
end

return slider