local colors = require("colors")
local drawing = require("drawing")

local missing = {}

function missing.draw(room, entity)
    local x = entity.x or 0
    local y = entity.y or 0

    local width = entity.width or 0
    local height = entity.height or 0

    local drawX = width > 0 and x or x - 2
    local drawY = height > 0 and y or y - 2
    local drawWidth = math.max(width, 5)
    local drawHeight = math.max(height, 5)

    drawing.callKeepOriginalColor(function()
        love.graphics.setColor(colors.entityMissingColor)
        love.graphics.rectangle("fill", drawX, drawY, drawWidth, drawHeight)
    end)
end

return missing