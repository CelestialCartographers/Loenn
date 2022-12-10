-- Fake window that acts like a notification device

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local history = require("history")
local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local mapItemUtils = require("map_item_utils")
local updater = require("updater")
local tasks = require("utils.tasks")

local notifications = require("ui.notification")

local eventNotifications = {}
local notificationHandlers = {}

function notificationHandlers:editorMapSaved(filename)
    local language = languageRegistry.getLanguage()
    local fromBackup = filename ~= loadedState.filename

    -- Only display the notification if the user manually saved
    if not fromBackup then
        notifications.notify(string.format(tostring(language.ui.notifications.editorMapSaved), filename))
    end
end

function notificationHandlers:editorMapSaveFailed(filename)
    local language = languageRegistry.getLanguage()

    notifications.notify(string.format(tostring(language.ui.notifications.editorMapSaveFailed), filename))
end

function notificationHandlers:editorMapVerificationFailed(filename)
    local language = languageRegistry.getLanguage()

    notifications.notify(string.format(tostring(language.ui.notifications.editorMapVerificationFailed), filename))
end

function notificationHandlers:editorMapLoaded(filename)
    local language = languageRegistry.getLanguage()

    notifications.notify(string.format(tostring(language.ui.notifications.editorMapLoaded), filename))
end

function notificationHandlers:editorMapNew(filename)
    local language = languageRegistry.getLanguage()

    notifications.notify(string.format(tostring(language.ui.notifications.editorMapNew), filename))
end

function notificationHandlers:editorMapLoadFailed(filename)
    local language = languageRegistry.getLanguage()

    notifications.notify(string.format(tostring(language.ui.notifications.editorMapLoadFailed), filename))
end

function notificationHandlers:editorHistoryUndoEmpty()
    local language = languageRegistry.getLanguage()

    notifications.notify(tostring(language.ui.notifications.editorHistoryUndoEmpty))
end

function notificationHandlers:editorHistoryRedoEmpty()
    local language = languageRegistry.getLanguage()

    notifications.notify(tostring(language.ui.notifications.editorHistoryRedoEmpty))
end

local function closePopup(popup)
    if popup.stateIndex == 2 then
        popup.durations[popup.stateIndex] = 0
    end
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:editorQuitWithChanges()
    local language = languageRegistry.getLanguage()

    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.notifications.editorQuitWithChanges)),
            uiElements.row({
                uiElements.button(tostring(language.ui.notifications.editorSaveAndQuit), function()
                    loadedState.saveCurrentMap(function(filename)
                        loadedState.defaultAfterSaveCallback(previousFilename, loadedState)

                        love.event.quit()
                    end)
                end),
                uiElements.button(tostring(language.ui.button.quit), function()
                    -- Update history to think we have no changes
                    history.madeChanges = false

                    love.event.quit()
                end),
                uiElements.button(tostring(language.ui.button.cancel), function()
                    closePopup(popup)
                end),
            })
        })
    end, -1)
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:editorLoadWithChanges(currentFile, filename)
    local language = languageRegistry.getLanguage()

    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.notifications.editorLoadWithChanges)),
            uiElements.row({
                uiElements.button(tostring(language.ui.notifications.editorSaveFirst), function()
                    loadedState.saveCurrentMap(function(previousFilename)
                        loadedState.defaultAfterSaveCallback(previousFilename, loadedState)

                        loadedState.loadFile(filename)
                        closePopup(popup)
                    end)
                end),
                uiElements.button(tostring(language.ui.notifications.editorDiscardChanges), function()
                    -- Update history to think we have no changes
                    history.madeChanges = false

                    loadedState.loadFile(filename)
                    closePopup(popup)
                end),
                uiElements.button(tostring(language.ui.button.cancel), function()
                    closePopup(popup)
                end),
            })
        })
    end, -1)
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:editorNewMapWithChanges()
    local language = languageRegistry.getLanguage()

    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.notifications.editorNewWithChanges)),
            uiElements.row({
                uiElements.button(tostring(language.ui.notifications.editorSaveFirst), function()
                    loadedState.saveCurrentMap(function(previousFilename)
                        loadedState.defaultAfterSaveCallback(previousFilename, loadedState)

                        loadedState.newMap()
                        closePopup(popup)
                    end)
                end),
                uiElements.button(tostring(language.ui.notifications.editorDiscardChanges), function()
                    -- Update history to think we have no changes
                    history.madeChanges = false

                    loadedState.newMap()
                    closePopup(popup)
                end),
                uiElements.button(tostring(language.ui.button.cancel), function()
                    closePopup(popup)
                end),
            })
        })
    end, -1)
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:editorRoomDelete(map, item)
    local language = languageRegistry.getLanguage()

    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.notifications.editorDeleteRoom)),
            uiElements.row({
                uiElements.button(tostring(language.ui.button.confirm), function()
                    mapItemUtils.deleteItem(map, item)
                    loadedState.selectItem(nil)

                    closePopup(popup)
                end),
                uiElements.button(tostring(language.ui.button.cancel), function()
                    closePopup(popup)
                end),
            })
        })
    end, -1)
end

-- TODO - Move over to modal when those are implemented
function notificationHandlers:updaterUpdateAvailable(latestVersion, currentVersion, shouldNotify)
    local language = languageRegistry.getLanguage()

    local updateTitle = string.format(tostring(language.ui.notifications.updaterUpdateFound), currentVersion, latestVersion)

    if shouldNotify then
        notifications.notify(function(popup)
            return uiElements.column({
                uiElements.label(updateTitle),
                uiElements.row({
                    uiElements.button(tostring(language.ui.notifications.updaterUpdateYes), function()
                        updater.update(latestVersion)
                        closePopup(popup)
                    end),
                    uiElements.button(tostring(language.ui.notifications.updaterUpdateNo), function()
                        closePopup(popup)
                    end),
                    uiElements.button(tostring(language.ui.notifications.updaterRemindMeLater), function()
                        updater.remindMeLater(latestVersion)
                        closePopup(popup)
                    end),
                    uiElements.button(tostring(language.ui.notifications.updaterDontRemindMeAgain), function()
                        updater.dontAskAgain(latestVersion)
                        closePopup(popup)
                    end),
                })
            })
        end, -1)
    end
end

function eventNotifications.getWindow()
    local handler = uiElements.group()

    handler:with(notificationHandlers)

    return handler
end

return eventNotifications