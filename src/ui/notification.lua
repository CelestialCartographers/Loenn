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

local edgePadding = 16

local popupStartDuration = 0.4
local popupStopDuration = 0.4

local function removePopupWindow(window)
    for i = #notificationWindows, 1, -1 do
        local target = notificationWindows[i]

        if target == window then
            table.remove(notificationWindows, i)
            notificationGroup:reflow()
            ui.root:recollect()
            window:removeSelf()

            if activeNotification == target then
                activeNotification = false
            end

            return
        end
    end
end

local function createPopupWindow(popup)
    local widgets = widgetUtils.getSimpleOverlayWidget(popup.widget, popup)
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
    })

    local closeButton = uiElements.button(uiElements.image("ui:icons/close"), function()
        removePopupWindow(panel)
    end):with({
        y = 0,

    }):with(uiUtils.rightbound)

    closeButton.style = {
        padding = 6
    }

    table.insert(widgets, closeButton)
    table.insert(notificationWindows, panel)

    row:reflow()
    notificationGroup:reflow()
    ui.root:recollect()

    return panel
end

local popupStates = {
    "starting",
    "waiting",
    "stopping"
}

local function closePopup(popup)
    if popup.stateIndex == 2 then
        popup.durations[popup.stateIndex] = 0
    end
end

function notificationPopup.notify(widget, duration)
    local popup = {
        widget = widget,
        durations = {
            popupStartDuration,
            duration or 3,
            popupStopDuration
        },
        timeAcc = 0,
        lerpPercent = 0,
        state = "starting",
        stateIndex = 1,
        close = closePopup
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
        local startX, startY = windowWidth - self.width - edgePadding, windowHeight + self.height + edgePadding
        local stopX, stopY = startX, windowHeight - self.height - edgePadding

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