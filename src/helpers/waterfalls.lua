local drawableRectangle = require("structs.drawable_rectangle")

local waterfallHelper = {}

function waterfallHelper.addWaveLineSprite(sprites, entityY, entityHeight, x, y, width, height, color)
    local rectangle = drawableRectangle.fromRectangle("fill", x, y, width, height, color)
    local bottomY = entityY + entityHeight

    if rectangle.y <= bottomY and rectangle.y + rectangle.height >= entityY then
        -- Ajust bottom
        if rectangle.y + rectangle.height > bottomY then
            rectangle.height = bottomY - rectangle.y
        end

        -- Adjust top
        if rectangle.y < entityY then
            rectangle.height += (rectangle.y - entityY)
            rectangle.y = entityY
        end

        if rectangle.height > 0 then
            table.insert(sprites, rectangle:getDrawableSprite())
        end
    end
end

return waterfallHelper