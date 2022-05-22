local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")

local widgetUtils = {}

function widgetUtils.removeWindowTitlebar(window)
    return window:with(function(el)
        table.remove(el.children, 1).parent = el
    end)
end

function widgetUtils.setWindowTitle(window, title)
    if window and window.titlebar and window.titlebar.label then
        window.titlebar.label.text = title
    end
end

function widgetUtils.addWindowCloseButton(window)
    if window and window.titlebar then
        local titlebar = window.titlebar
        local closeButton = uiElements.buttonClose()

        -- Wild guess, looks decent
        closeButton.style.padding = titlebar.style.padding * 2 - 1
        closeButton.cb = function()
            window:removeSelf()
        end

        table.insert(titlebar.children, closeButton)
    end
end

function widgetUtils.getSimpleOverlayWidget(widget, ...)
    local widgetType = utils.typeof(widget)

    if widgetType == "string" then
        widget = uiElements.label(widget)

    elseif widgetType == "Image" then
        widget = uiElements.image(widget)

    elseif widgetType == "table" then
        if widget.image then
            -- Sprite metadata
            widget = uiElements.image(widget.image, widget.quad)

        elseif #widget > 0 then
            -- Colored text
            widget = uiElements.label(widget)
        end

    elseif widgetType == "function" then
        widget = widget(...)
    end

    -- Make sure the processed widget is a table
    if utils.typeof(widget) ~= "table" then
        widget = {widget}
    end

    return widget
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

        if window.parent then
            window.parent:reflow()
        end

        ui.root:recollect(false, true)
    end
end

function widgetUtils.lerpWindowPosition(window, fromX, fromY, toX, toY, percent, threshold, padding)
    padding = padding or 16
    threshold = threshold or 4

    local newX, newY = math.floor(fromX + (toX - fromX) * percent), math.floor(fromY + (toY - fromY) * percent)

    widgetUtils.moveWindow(window, newX, newY, threshold, false, padding)
end

function widgetUtils.focusMainEditor()
    ui.interactiveIterate(ui.focusing, "onUnfocus")
    ui.focusing = false
end

function widgetUtils.cursorDeltaFromElementCenter(element, x, y)
    local elementX, elementY = element.screenX, element.screenY
    local elementWidth, elementHeight = element.width, element.height

    return x - elementX - elementWidth / 2, y - elementY - elementHeight / 2
end

return widgetUtils