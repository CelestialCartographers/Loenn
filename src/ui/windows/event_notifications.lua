-- Fake window that acts like a notification device
-- TODO - Use language file

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local history = require("history")
local loadedState = require("loaded_state")

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

local function closePopup(popup)
    if popup.stateIndex == 2 then
        popup.durations[popup.stateIndex] = 0
    end
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:editorQuitWithChanges()
    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label("You have unsaved pending changes.\nAre you sure you want to quit?"),
            uiElements.row({
                uiElements.button("Quit", function()
                    -- Update history to think we have no changes
                    history.madeChanges = false

                    love.event.quit()
                end),
                uiElements.button("Cancel", function()
                    closePopup(popup)
                end),
            })
        })
    end, -1)
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:editorLoadWithChanges(currentFile, filename)
    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label("You have unsaved pending changes.\nAre you sure you want to load this map?"),
            uiElements.row({
                uiElements.button("Yes", function()
                    -- Update history to think we have no changes
                    history.madeChanges = false

                    loadedState.loadFile(filename)
                    closePopup(popup)
                end),
                uiElements.button("Cancel", function()
                    closePopup(popup)
                end),
            })
        })
    end, -1)
end

function eventNotifications.getWindow()
    local handler = uiElements.panel()

    handler:with(notificationHandlers)

    return handler
end

return eventNotifications