local colors = require("colors")

local missing = {}

function missing.draw(room, entity)
    local x = entity.x or 0
    local y = entity.y or 0

    love.graphics.setColor(colors.entityMissingColor)
    love.graphics.rectangle("fill", x - 2, y - 2, 5, 5)
    love.graphics.setColor(colors.default)
end

return missing