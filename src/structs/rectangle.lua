local rectangles = {}

local rectangleMt = {}
rectangleMt.__index = {}

function rectangles.create(x, y, width, height)
    local rectangle = {
        _type = "rectangle"
    }

    rectangle.x = width < 0 and x + width or x
    rectangle.y = height < 0 and y + height or y

    rectangle.width = math.abs(width)
    rectangle.height = math.abs(height)

    return setmetatable(rectangle, rectangleMt)
end

return rectangles