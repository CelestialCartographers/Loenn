local utils = require("utils")

local drawing = {}

function drawing.drawSprite(spriteMeta, x, y, r, sx, sy, ox, oy)
    love.graphics.draw(spriteMeta.image, spriteMeta.quad, x, y, r, sx, sy, ox, oy)
end

function drawing.getCurvePoint(start, stop, control, percent)
    local startMul = (1 - percent)^2
    local controlMul = 2 * (1 - percent) * percent
    local stopMul = percent^2

    local x = start[1] * startMul + control[1] * controlMul + stop[1] * stopMul
    local y = start[2] * startMul + control[2] * controlMul + stop[2] * stopMul

    return x, y
end

function drawing.getSimpleCurve(start, stop, control, resolution)
    control = control or {(start[1] + stop[1]) / 2, (start[2] + stop[2]) / 2}
    resolution = resolution or 16

    local res = {}

    for i = 0, resolution do
        local x, y = drawing.getCurvePoint(start, stop, control, i / resolution)

        table.insert(res, x)
        table.insert(res, y)
    end

    return res
end

function drawing.getRelativeQuad(spriteMeta, x, y, width, height, hideOverflow, realSize)
    local image = spriteMeta.image
    local imageWidth, imageHeight = image:getDimensions()
    local quadX, quadY, quadWidth, quadHeight = spriteMeta.quad:getViewport()
    local offsetX, offsetY = 0, 0

    if realSize then
        offsetX = spriteMeta.offsetX
        offsetY = spriteMeta.offsetY

        x += offsetX
        y += offsetY

        if x > 0 then
            offsetX = 0
        end

        if y > 0 then
            offsetY = 0
        end
    end

    -- Make sure the width/height doesn't go outside the original quad
    if hideOverflow ~= false then
        width = math.min(width, quadWidth - x)
        height = math.min(height, quadHeight - y)

        if x < 0 then
            width += x
            x = 0
        end

        if y < 0 then
            height += y
            y = 0
        end
    end

    return love.graphics.newQuad(quadX + x, quadY + y, width, height, imageWidth, imageHeight), offsetX, offsetY
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

function drawing.addCenteredText(batch, text, x, y, width, height, font, fontSize, trim)
    font = font or love.graphics.getFont()
    fontSize = fontSize or 1

    if trim ~= false then
        text = utils.trim(text)
    end

    local fontHeight = font:getHeight()
    local fontLineHeight = font:getLineHeight()
    local longest, lines = font:getWrap(text, width / fontSize)
    local textHeight = (#lines - 1) * (fontHeight * fontLineHeight) + fontHeight

    local offsetX = 1
    local offsetY = math.floor((height - textHeight) / 2) + 1
    local wrapLimit = math.floor(width / fontSize)

    batch:addf(text, wrapLimit, "center", x + offsetX, y + offsetY, 0, fontSize, fontSize)
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

function drawing.getDashedLineSegments(x1, y1, x2, y2, dash, space)
    dash = dash or 6
    space = space or 4

    local length = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    local progress = 0
    local segments = {}

    while progress < length do
        local startPercent = progress / length
        local stopPercent = math.min(length, progress + dash) / length
        local startX = x1 + (x2 - x1) * startPercent
        local startY = y1 + (y2 - y1) * startPercent
        local stopX = x1 + (x2 - x1) * stopPercent
        local stopY = y1 + (y2 - y1) * stopPercent

        table.insert(segments, {startX, startY, stopX, stopY})

        progress += dash + space
    end

    return segments
end

function drawing.drawDashedLine(x1, y1, x2, y2, dash, space)
    local segments = drawing.getDashedLineSegments(x1, y1, x2, y2, dash, space)

    for _, segment in ipairs(segments) do
        love.graphics.line(segment)
    end
end

return drawing