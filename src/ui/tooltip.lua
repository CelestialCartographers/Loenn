local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local padding = 16
local targetElement
local tooltipVisible = false
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

function tooltipHandler.tooltipWindowUpdate(orig, self)
    orig(self)

    local hovered = ui.hovering

    if hovered ~= targetElement then
        if hovered then
            local tooltipText = rawget(hovered, "tooltipText")

            if tooltipText then
                tooltipWindow.children[1]:setText(tooltipText)
            end

            targetElement = hovered
            tooltipVisible = not not tooltipText

        else
            targetElement = false
            tooltipVisible = false
        end
    end

    if tooltipVisible then
        local cursorX, cursorY = love.mouse.getPosition()

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