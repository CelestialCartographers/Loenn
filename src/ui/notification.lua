-- TODO - Change notification start point and direction? Allow notifications from multiple locations?
-- TODO - Support image argument
-- TODO - "Rich labels", some minimal markup support
-- TODO - Add close button in notification panel

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local notificationPopup = {}

local notificationWindow
local notificationLabel = uiElements.label("")
local notificationQueue = {}

local popupStartDuration = 0.4
local popupStopDuration = 0.4

local function lerpWindowPosition(fromX, fromY, toX, toY, percent)
    local newX, newY = fromX + (toX - fromX) * percent, fromY + (toY - fromY) * percent

    if notificationWindow.x ~= newX or notificationWindow.y ~= newY then
        notificationWindow.x = fromX + (toX - fromX) * percent
        notificationWindow.y = fromY + (toY - fromY) * percent

        notificationWindow.parent:reflow()
        ui.root:recollect(false, true)
    end
end

function notificationPopup.popup(message, image, duration)
    local popup = {
        message = message,
        image = image,
        visibleDuration = duration or 3,
        timeAcc = 0,
        state = "starting"
    }

    table.insert(notificationQueue, popup)
end

function notificationPopup.update(orig, self, dt)
    orig(dt)

    local popup = notificationQueue[1]

    if popup then
        local windowWidth, windowHeight = love.graphics.getDimensions()
        local startX, startY = windowWidth - notificationWindow.width - 4, windowHeight + notificationWindow.height + 4
        local stopX, stopY = startX, windowHeight - notificationWindow.height - 4

        popup.timeAcc += dt

        if popup.state == "starting" then
            notificationLabel:setText(popup.message)

            local percent = popup.timeAcc / popupStartDuration

            lerpWindowPosition(startX, startY, stopX, stopY, percent)

            if popup.timeAcc > popupStartDuration then
                popup.state = "waiting"
                popup.timeAcc -= popupStartDuration
            end

        elseif popup.state == "waiting" then
            -- Popup shouldn't go away if hovered
            if notificationWindow.hovered then
                popup.timeAcc -= dt
            end

            if popup.timeAcc > popup.visibleDuration then
                popup.state = "stopping"
                popup.timeAcc -= popup.visibleDuration
            end

            lerpWindowPosition(startX, startY, stopX, stopY, 1)

        elseif popup.state == "stopping" then
            local percent = popup.timeAcc / popupStopDuration

            lerpWindowPosition(startX, startY, stopX, stopY, 1 - percent)

            if popup.timeAcc > popupStopDuration then
                table.remove(notificationQueue, 1)
            end
        end
    end
end

function notificationPopup.getPopupWindow()
    if not notificationWindow then
        notificationLabel = uiElements.label("")
        notificationWindow = uiElements.panel({
            notificationLabel
        }):with({
            updateHidden = true
        }):hook({
            update = notificationPopup.update
        })
    end

    return notificationWindow
end

return notificationPopup