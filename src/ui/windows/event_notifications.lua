-- Fake window that acts like a notification device
-- TODO - Use language file

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local notifications = require("ui.notification")

local eventNotifications = {}
local notificationHandlers = {}

function notificationHandlers:editorMapSaved(filename)
    notifications.notify(string.format("Saved map: %s", filename))
end

function notificationHandlers:editorMapSaveFailed(filename)
    notifications.notify(string.format("Failed to save map: %s", filename))
end

function notificationHandlers:editorMapLoaded(filename)
    notifications.notify(string.format("Loaded map: %s", filename))
end

function notificationHandlers:editorMapLoadFailed(filename)
    notifications.notify(string.format("Failed to load map: %s", filename))
end

function notificationHandlers:editorHistoryUndoEmpty()
    notifications.notify("Unable to undo, end of history")
end

function notificationHandlers:editorHistoryRedoEmpty()
    notifications.notify("Unable to redo, end of history")
end

function eventNotifications.getWindow()
    local handler = uiElements.panel()

    handler:with(notificationHandlers)

    return handler
end

return eventNotifications