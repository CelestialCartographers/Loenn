local drawableRectangle = require("structs.drawable_rectangle")
local drawing = require("drawing")

local drawableLine = {}

local drawableLineMt = {}
drawableLineMt.__index = {}

local lineExtraWidth = 0.2

local function getRotatedRectangleSprite(x1, y1, x2, y2, color, thickness, smooth)
    local theta = math.atan2(y2 - y1, x2 - x1)
    local magnitude = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)

    local halfThickenss = thickness / 2
    local x = smooth and x1 - lineExtraWidth + halfThickenss or x1 + halfThickenss
    local y = y1 - halfThickenss
    local width = smooth and magnitude + lineExtraWidth * 2 or magnitude

    local sprite = drawableRectangle.fromRectangle("fill", x, y, width, thickness, color):getDrawableSprite()

    sprite.rotation = theta

    return sprite
end

function drawableLineMt.__index:getDrawableSprite()
    local points = self.points
    local color = self.color
    local thickness = self.thickness

    local sprites = {}

    for i = 3, #points, 2 do
        local smooth = i > 3 and i < #points - 2
        local x1, y1, x2, y2 = points[i - 2], points[i - 1], points[i], points[i + 1]

        table.insert(sprites, getRotatedRectangleSprite(x1, y1, x2, y2, color, thickness, smooth))
    end

    return sprites
end

function drawableLineMt.__index:draw()
    local color = self.color
    local points = self.points
    local thickness = self.thickness
    local previousThickenss = love.graphics.getLineWidth()

    love.graphics.setLineWidth(thickness)

    if color then
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(color)
            love.graphics.line(points)
        end)

    else
        love.graphics.line(points)
    end

    love.graphics.setLineWidth(previousThickenss)
end

function drawableLine.fromPoints(points, color, thickness)
    local line = {
        _type = "drawableLine"
    }

    line.points = points
    line.color = color
    line.thickness = thickness or 1

    return setmetatable(line, drawableLineMt)
end

return drawableLine