local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")

local tooltipWaitDuration = 0.5
local lastX, lastY = 0, 0
local waitedDuration = 0

local targetElement
local tooltipExists = false
local tooltipWindow

local tooltipHandler = {}

function tooltipHandler.tooltipWindowUpdate(orig, self, dt)
    orig(self, dt)

    local cursorX, cursorY = love.mouse.getPosition()
    local hovered = ui.hovering
    local waitedEnough = waitedDuration >= tooltipWaitDuration

    if not waitedEnough then
        if cursorX == lastX and cursorY == lastY then
            waitedDuration += dt

        else
            lastX, lastY = cursorX, cursorY
            waitedDuration = 0
        end
    end

    if hovered ~= targetElement then
        waitedDuration = 0

        if hovered then
            local tooltipText = rawget(hovered, "tooltipText")

            if tooltipText then
                tooltipWindow.children[1]:setText(tooltipText)
            end

            targetElement = hovered
            tooltipExists = not not tooltipText

        else
            targetElement = false
            tooltipExists = false
        end
    end

    if tooltipExists and waitedEnough then
        widgetUtils.moveWindow(tooltipWindow, cursorX, cursorY - tooltipWindow.height)

    elseif tooltipWindow.x ~= -1024 or tooltipWindow.y ~= -1024 then
        widgetUtils.moveWindow(tooltipWindow, -1024, -1024, 0, false)
    end
end

function tooltipHandler.getTooltipWindow()
    if not tooltipWindow then
        tooltipWindow = uiElements.panel({
            uiElements.label("Test")
        }):with({
            interactive = -2,
            updateHidden = true
        }):hook({
            update = tooltipHandler.tooltipWindowUpdate
        })
    end

    return tooltipWindow
end

return tooltipHandler