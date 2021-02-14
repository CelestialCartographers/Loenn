local utils = require("utils")

local drawing = {}

function drawing.drawSprite(spriteMeta, x, y, r, sx, sy, ox, oy)
    love.graphics.draw(spriteMeta.image, spriteMeta.quad, x, y, r, sx, sy, ox, oy)
end

function drawing.getCurvePoint(start, stop, control, percent)
    local startMul = (1 - percent)^2
    local controlMul = 2 * (1 - percent) * percent
    local stopMul = percent^2

    return {
        start[1] * startMul + control[1] * controlMul + stop[1] * stopMul,
        start[2] * startMul + control[2] * controlMul + stop[2] * stopMul,
    }
end

function drawing.getSimpleCurve(start, stop, control, resolution)
    control = control or {(start[1] + stop[1]) / 2, (start[2] + stop[2]) / 2}
    resolution = resolution or 16

    local res = {}

    for i = 0, resolution do
        table.insert(res, drawing.getCurvePoint(start, stop, control, i / resolution))
    end

    return res
end

function drawing.getRelativeQuad(spriteMeta, x, y, width, height, overflow)
    local image = spriteMeta.image
    local imageWidth, imageHeight = image:getDimensions()
    local quadX, quadY, quadWidth, quadHeight = spriteMeta.quad:getViewport

    -- Make sure the width/height doesn't go outside the original quad
    if overflow ~= false then
        width = math.min(width, quadWidth - x)
        height = math.min(height, quadHeight - y)
    end

    return love.graphics.newQuad(quadX + x, quadY + y, width, height, imageWidth, imageHeight)
end

-- TODO - Vertical offset is wrong based on scale?
function drawing.printCenteredText(text, x, y, width, height, font, fontSize, trim)
    font = font or love.graphics.getFont()
    fontSize = fontSize or 1

    if trim ~= false then
        text = utils.trim(text)
    end

    local longest, lines = font:getWrap(text, width / fontSize)
    local textHeight = #lines * (font:getHeight() * font:getLineHeight())

    local offsetX = 0
    local offsetY = (height - textHeight) / 2

    love.graphics.push()

    love.graphics.translate(x + offsetX, y + offsetY)
    love.graphics.scale(fontSize, fontSize)

    love.graphics.printf(text, 0, 0, width / fontSize, "center")

    love.graphics.pop()
end

function drawing.getTrianglePoints(x, y, theta, height)
    theta = theta - math.pi / 2

    local px1 = x + height * math.cos(theta + math.pi / 4)
    local py1 = y + height * math.sin(theta + math.pi / 4)

    local px2 = x + height * math.cos(theta - math.pi / 4)
    local py2 = y + height * math.sin(theta - math.pi / 4)

    return x, y, px1, py1, px2, py2
end

function drawing.triangle(mode, x, y, theta, height)
    love.graphics.polygon(mode, drawing.getTrianglePoints(x, y, theta, height))
end

function drawing.callKeepOriginalColor(func)
    local pr, pg, pb, pa = love.graphics.getColor()

    func()

    love.graphics.setColor(pr, pg, pb, pa)
end

return drawing