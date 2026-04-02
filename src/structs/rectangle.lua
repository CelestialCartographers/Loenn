local dataUtils = require("utils.data")

local rectangles = {}

function rectangles.create(x, y, width, height)
    local rectangle = dataUtils.newTable(0, 5)

    rectangle._type = "rectangle"

    rectangle.x = width < 0 and x + width or x
    rectangle.y = height < 0 and y + height or y

    rectangle.width = math.abs(width)
    rectangle.height = math.abs(height)

    return rectangle
end

return rectangles