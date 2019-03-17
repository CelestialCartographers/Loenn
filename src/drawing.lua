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
    local control = control or {(start[1] + stop[1]) / 2, (start[2] + stop[2]) / 2}
    local resolution = resolution or 16
    local res = $()

    for i = 0, resolution do
        res += drawing.getCurvePoint(start, stop, control, i / resolution)
    end

    return res()
end

function drawing.getRelativeQuad(spriteMeta, x, y, width, height)
    local image = spriteMeta.image
    local qx, qy, qw, qh = image.quad:getViewport

    return love.graphics.newQuad(qx + x, qy + y, width, height, image:getDimensions)
end

return drawing