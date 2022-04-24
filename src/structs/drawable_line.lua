local drawableRectangle = require("structs.drawable_rectangle")
local drawing = require("utils.drawing")
local utils = require("utils")

local drawableLine = {}

local drawableLineMt = {}
drawableLineMt.__index = {}

local lineExtraWidth = 0.2

local function getRotatedRectangleSprite(x1, y1, x2, y2, color, thickness, smooth, offsetX, offsetY, magnitudeOffset, depth)
    local theta = math.atan2(y2 - y1, x2 - x1)
    local magnitude = math.sqrt((x1 - x2)^2 + (y1 - y2)^2) + magnitudeOffset

    local halfThickenss = thickness / 2
    local x = smooth and x1 - lineExtraWidth or x1
    local y = y1
    local width = smooth and magnitude + lineExtraWidth * 2 or magnitude

    local sprite = drawableRectangle.fromRectangle("fill", x, y, width, thickness, color):getDrawableSprite()

    sprite:setOffset(offsetX / magnitude, 0.5 / thickness + offsetY / thickness)
    sprite.rotation = theta
    sprite.depth = depth

    return sprite
end

function drawableLineMt.__index:getDrawableSprite()
    local points = self.points
    local color = self.color
    local thickness = self.thickness
    local offsetX, offsetY = self.offsetX, self.offsetY
    local magnitudeOffset = self.magnitudeOffset
    local depth = self.depth

    local sprites = {}

    for i = 3, #points, 2 do
        local x1, y1, x2, y2 = points[i - 2], points[i - 1], points[i], points[i + 1]

        table.insert(sprites, getRotatedRectangleSprite(x1, y1, x2, y2, color, thickness, true, offsetX, offsetY, magnitudeOffset, depth))
    end

    return sprites
end

function drawableLineMt.__index:setOffset(x, y)
    self.offsetX = x
    self.offsetY = y
end

function drawableLineMt.__index:setMagnitudeOffset(offset)
    self.magnitudeOffset = offset
end

function drawableLineMt.__index:setThickness(thickness)
    self.thickness = thickness
end

function drawableLineMt.__index:setColor(color)
    local tableColor = utils.getColor(color)

    if tableColor then
        self.color = tableColor
    end
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

function drawableLine.fromPoints(points, color, thickness, offsetX, offsetY, magnitudeOffset)
    local line = {
        _type = "drawableLine"
    }

    line.points = points
    line.color = utils.getColor(color)
    line.thickness = thickness or 1
    line.offsetX = offsetX or 0
    line.offsetY = offsetY or 0
    line.magnitudeOffset = magnitudeOffset or 0

    return setmetatable(line, drawableLineMt)
end

return drawableLine