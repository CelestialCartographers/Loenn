local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = {}

function widgetUtils.removeWindowTitlebar(window)
    return window:with(function(el)
        table.remove(el.children, 1).parent = el
    end)
end

function widgetUtils.moveWindow(window, newX, newY, threshold, clamp, padding)
    padding = padding or 16
    threshold = threshold or 4

    local windowWidth, windowHeight = love.graphics.getDimensions()
    local currentX, currentY = window.x, window.y

    if clamp ~= false then
        newX = math.max(math.min(windowWidth - window.width - padding, newX), padding)
        newY = math.max(math.min(windowHeight - window.height - padding, newY), padding)
    end

    if math.abs(currentX - newX) > threshold or math.abs(currentY - newY) > threshold then
        window.x = newX
        window.y = newY

        window.parent:reflow()
        ui.root:recollect(false, true)
    end
end

function widgetUtils.lerpWindowPosition(window, fromX, fromY, toX, toY, percent, threshold, padding)
    padding = padding or 16
    threshold = threshold or 4

    local newX, newY = math.floor(fromX + (toX - fromX) * percent), math.floor(fromY + (toY - fromY) * percent)

    widgetUtils.moveWindow(window, newX, newY, threshold, false, padding)
end

return widgetUtils