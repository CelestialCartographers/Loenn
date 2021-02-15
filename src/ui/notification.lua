-- TODO - Change notification start point and direction? Allow notifications from multiple locations?
-- TODO - "Rich labels", some minimal markup support
-- TODO - Add close button in notification panel? Click to close?
-- TODO - Lazy layout update the notifcation back off screen, visual odities if window is resized

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")

local notificationPopup = {}

local activeNotification
local notificationWindows = {}
local notificationGroup = uiElements.group(notificationWindows)

local popupStartDuration = 0.4
local popupStopDuration = 0.4

local function createPopupWindow(popup)
    local widgets = {
        uiElements.label(popup.message)
    }

    if popup.image then
        local image = uiElements.image(popup.image, popup.quad)

        table.insert(widgets, 1, image)
    end

    local row = uiElements.row(widgets)

    row.style.bg = {}
    row.style.padding = 0

    local panel = uiElements.panel({row}):hook({
        update = notificationPopup.update
    }):with({
        updateHidden = true,
        interactive = 2,

        x = -1024,
        y = -1024,

        popup = popup,
        padding = 16
    })

    table.insert(notificationWindows, panel)
    notificationGroup:reflow()
    ui.root:recollect()

    return panel
end

local function removePopupWindow(window)
    for i, target in ipairs(notificationWindows) do
        if target == window then
            table.remove(notificationWindows, i)
            notificationGroup:reflow()
            ui.root:recollect()
            window:removeSelf()

            return
        end
    end
end

local popupStates = {
    "starting",
    "waiting",
    "stopping"
}

function notificationPopup.notify(message, duration, image, quad)
    local popup = {
        message = message,
        image = image,
        quad = quad,
        durations = {
            popupStartDuration,
            duration or 3,
            popupStopDuration
        },
        timeAcc = 0,
        lerpPercent = 0,
        state = "starting",
        stateIndex = 1
    }

    return createPopupWindow(popup)
end

function notificationPopup.update(orig, self, dt)
    orig(dt)

    if not activeNotification then
        activeNotification = self
    end

    if activeNotification ~= self then
        return
    end

    local popup = self.popup

    if popup and not popup.done then
        local stateDuration = popup.durations[popup.stateIndex]

        local windowWidth, windowHeight = love.graphics.getDimensions()
        local startX, startY = windowWidth - self.width - self.padding, windowHeight + self.height + self.padding
        local stopX, stopY = startX, windowHeight - self.height - self.padding

        popup.timeAcc += dt

        widgetUtils.lerpWindowPosition(self, startX, startY, stopX, stopY, popup.lerpPercent)

        if stateDuration then
            if popup.timeAcc > stateDuration and stateDuration ~= -1 then
                popup.timeAcc -= stateDuration
                popup.stateIndex += 1
                popup.state = popupStates[popup.stateIndex]
            end

        else
            popup.done = true
        end

        if popup.state == "starting" then
            popup.lerpPercent = popup.timeAcc / popupStartDuration

        elseif popup.state == "waiting" then
            -- Popup shouldn't go away if hovered
            if self.hovered then
                popup.timeAcc = 0
            end

            popup.lerpPercent = 1

        elseif popup.state == "stopping" then
            popup.lerpPercent = 1 - popup.timeAcc / popupStopDuration
        end

    else
        removePopupWindow(self)

        activeNotification = false
    end
end

function notificationPopup.getPopupWindow()
    return notificationGroup
end

return notificationPopup