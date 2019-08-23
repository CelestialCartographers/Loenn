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

    local res = $()

    for i = 0, resolution do
        res += drawing.getCurvePoint(start, stop, control, i / resolution)
    end

    return res()
end

function drawing.getRelativeQuad(spriteMeta, x, y, width, height)
    local image = spriteMeta.image
    local qx, qy, qw, qh = spriteMeta.quad:getViewport

    return love.graphics.newQuad(qx + x, qy + y, width, height, image:getDimensions)
end

-- TODO - Vertical offset is wrong based on scale?
function drawing.printCenteredText(text, x, y, width, height, font, fontSize, trim)
    font = font or love.graphics.getFont()
    fontSize = fontSize or 1

    trim = trim or trim == nil
    text = trim and utils.trim(text) or text

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

return drawing