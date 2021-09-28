local drawing = require("drawing")
local utils = require("utils")
local drawableLine = require("structs.drawable_line")
local drawableRectangle = require("structs.drawable_rectangle")

local flaglineHelper = {}

function flaglineHelper.getFlagLineSprites(room, entity, options)
    local sprites = {}
    local x, y = entity.x, entity.y

    utils.setSimpleCoordinateSeed(x, y)

    local firstNode = entity.nodes[1]
    local start = {x, y}
    local stop = {firstNode.x, firstNode.y}
    local curveLength = math.sqrt((start[1] - stop[1])^2 + (start[2] - stop[2])^2)

    if x > firstNode.x then
        start, stop = stop, start
    end

    local control = {
        (start[1] + stop[1]) / 2,
        (start[2] + stop[2]) / 2 + curveLength / 8 * 0.3
    }

    local points = drawing.getSimpleCurve(start, stop, control)
    local lineSprites = drawableLine.fromPoints(points, options.lineColor, 1):getDrawableSprite()
    local flagParts = {}

    local progress = 0
    local drawFlag = false
    local prevPoint = start
    local droopAmount = options.droopAmount or 0.6

    while progress < 1 do
        local color = options.colors[math.random(1, #options.colors)]
        local highlightColor = {color[1] + 0.1, color[2] + 0.1, color[3] + 0.1}
        local height = math.random(options.minFlagHeight, options.maxFlagHeight)
        local length = math.random(options.minFlagLength, options.maxFlagLength)
        local step = math.random(options.minSpace, options.maxSpace)

        progress += (drawFlag and length or step) / curveLength

        local point = {drawing.getCurvePoint(start, stop, control, progress)}

        if progress < 1 and drawFlag then
            local droop = length * droopAmount
            local droopControl = {(prevPoint[1] + point[1]) / 2, (prevPoint[2] + point[2]) / 2 + droop * 1.4}
            local prevFlagPointX, prevFlagPointY = drawing.getCurvePoint(prevPoint, point, droopControl, 1 / length)

            for i = 0, length - 1 do
                local flagPointX, flagPointY = drawing.getCurvePoint(prevPoint, point, droopControl, i / length)

                if flagPointX > prevFlagPointX then
                    local segmentWidth = flagPointX - prevFlagPointX + 1

                    if segmentWidth > 0 then
                        local rectangleX, rectangleY = math.floor(flagPointX), math.floor(flagPointY)
                        local flagSegment = drawableRectangle.fromRectangle("fill", rectangleX, rectangleY, math.ceil(segmentWidth), height - 1, color)

                        table.insert(flagParts, flagSegment)
                    end
                end

                prevFlagPointX, prevFlagPointY = flagPointX, flagPointY
            end

            local leftHighlight = drawableRectangle.fromRectangle("fill", prevPoint[1], prevPoint[2], 1, height - 1, highlightColor)
            local rightHighlight = drawableRectangle.fromRectangle("fill", point[1], point[2], 1, height - 1, highlightColor)

            local leftPin = drawableRectangle.fromRectangle("fill", prevPoint[1], prevPoint[2] - 1, 1, 3)
            local rightPin = drawableRectangle.fromRectangle("fill", point[1], point[2] - 1, 1, 3)

            table.insert(flagParts, leftHighlight)
            table.insert(flagParts, rightHighlight)
            table.insert(flagParts, leftPin)
            table.insert(flagParts, rightPin)
        end

        prevPoint = point
        drawFlag = not drawFlag
    end

    for _, line in ipairs(lineSprites) do
        table.insert(sprites, line)
    end

    for _, part in ipairs(flagParts) do
        table.insert(sprites, part:getDrawableSprite())
    end

    return sprites
end

function flaglineHelper.getFlaglineSelection(room, entity)
    local main = utils.rectangle(entity.x - 2, entity.y - 2, 5, 5)
    local nodes = {}

    if entity.nodes then
        for i, node in ipairs(entity.nodes) do
            nodes[i] = utils.rectangle(node.x - 2, node.y - 2, 5, 5)
        end
    end

    return main, nodes
end

return flaglineHelper