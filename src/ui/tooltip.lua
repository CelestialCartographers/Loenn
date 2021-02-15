local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local padding = 16
local tooltipWaitDuration = 0.5
local lastX, lastY = 0, 0
local waitedDuration = 0

local targetElement
local tooltipExists = false
local tooltipWindow


local tooltipHandler = {}

local function moveTooltipWindow(window, newX, newY, threshold, clamp)
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
        moveTooltipWindow(tooltipWindow, cursorX, cursorY - tooltipWindow.height)

    else
        moveTooltipWindow(tooltipWindow, -1024, -1024, 0, false)
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