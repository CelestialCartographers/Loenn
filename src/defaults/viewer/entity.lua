local colors = require("colors")
local drawing = require("drawing")

local missing = {}

function missing.draw(room, entity)
    local x = entity.x or 0
    local y = entity.y or 0

    drawing.callKeepOriginalColor(function()
        love.graphics.setColor(colors.entityMissingColor)
        love.graphics.rectangle("fill", x - 2, y - 2, 5, 5)
    end)
end

return missing