local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local history = require("history")
local debugUtils = require("debug_utils")
local notifications = require("ui.notification")
local sceneHandler = require("scene_handler")
local updater = require("updater")
local configs = require("configs")

local utils = require("utils")
local languageRegistry = require("language_registry")

local roomEditor = require("ui.room_editor")
local stylegroundEditor = require("ui.styleground_editor")

local menubar = {}

local function deleteCurrentRoom()
    local map = loadedState.map
    local item = loadedState.getSelectedItem()

    if map and item then
        sceneHandler.sendEvent("editorRoomDelete", map, item)
    end
end

local function checkForUpdates()
    updater.checkForUpdates(true)
end

local function notYetImplementedNotification()
    local language = languageRegistry.getLanguage()
    local text = tostring(language.ui.menubar.not_yet_implemented)

    notifications.notify(text)
end

-- debugUtils.reloadUI might change, wrap in function
local function reloadUI()
    debugUtils.reloadUI()
end

local addDebug = configs.debug.enableDebugOptions
local debugMenu = {"debug", {
    {"debug_reload", {
        {"debug_reload_everything", debugUtils.reloadEverything},
        {"debug_reload_scenes", debugUtils.reloadScenes},
        {"debug_reload_tools", debugUtils.reloadTools},
        {"debug_reload_entities", debugUtils.reloadEntities},
        {"debug_reload_triggers", debugUtils.reloadTriggers},
        {"debug_reload_effects", notYetImplementedNotification},
        {"debug_reload_user_interface", reloadUI},
        {"debug_reload_language_files", debugUtils.reloadLanguageFiles}
    }},
    {"debug_redraw_map", debugUtils.redrawMap},
    {"debug_test_console", debugUtils.debug}
}}

-- Tree of menubar items
-- First element is translation key
-- Second element is a sub tree or a function callback
-- Third is whether or not the submenu should be closed after the callback is done
-- Closes by default, some menu items might not want to close the menu, for example "View" toggles
menubar.menubar = {
    {"file", {
        {"file_new", loadedState.newMap},
        {"file_open", loadedState.openMap},
        {"file_recent", notYetImplementedNotification},
        {},
        {"file_save", loadedState.saveCurrentMap},
        {"file_save_as", loadedState.saveAsCurrentMap},
        {},
        {"file_exit", love.event.quit}
    }},
    {"edit", {
        {"edit_undo", history.undo},
        {"edit_redo", history.redo},
        {},
        {"edit_settings", notYetImplementedNotification}
    }},
    {"view", notYetImplementedNotification},
    {"map", {
        {"map_stylegrounds", stylegroundEditor.editStylegrounds},
        {"map_metadata", notYetImplementedNotification}
    }},
    {"room", {
        {"room_add", roomEditor.createNewRoom},
        {"room_edit", roomEditor.editExistingRoom},
        {},
        {"room_delete", deleteCurrentRoom}
    }},
    -- Only add if enabled
    addDebug and debugMenu or false,
    {"help", {
        {"help_check_for_updates", checkForUpdates},
        {"help_about", notYetImplementedNotification}
    }}
}

local function addLanguageStrings(menu, language)
    if type(menu) == "table" then
        local languageKey = menu[1]
        local languageKeyType = type(languageKey)

        if languageKeyType == "string" then
            menu[1] = tostring(language.ui.menubar[languageKey])
        end

        for _, sub in pairs(menu) do
            addLanguageStrings(sub, language)
        end
    end
end

local function wrapInSubmenuClosers(menu)
    if type(menu) == "table" then
        local callback = menu[2]
        local shouldCloseMenu = menu[3]
        local callbackType = type(callback)

        if callbackType == "function" or callbackType == "nil" then
            menu[2] = function(self)
                if callback then
                    callback()
                end

                if shouldCloseMenu ~= false then
                    if self.parent:is("menuItemSubmenu") then
                        self.parent:removeSelf()
                    end
                end
            end
        end

        for _, sub in pairs(menu) do
            wrapInSubmenuClosers(sub)
        end
    end
end

local function removeFalseEntries(menu)
    for i = #menu, 1, -1 do
        if not menu[i] then
            table.remove(menu, i)
        end
    end
end

function menubar.getMenubar()
    local preparedMenubar = utils.deepcopy(menubar.menubar)
    local language = languageRegistry.getLanguage()

    removeFalseEntries(preparedMenubar)
    wrapInSubmenuClosers(preparedMenubar)
    addLanguageStrings(preparedMenubar, language)

    return uiElements.topbar(preparedMenubar)
end

return menubar