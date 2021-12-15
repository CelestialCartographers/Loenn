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
    {"reload", {
        {"reload_everything", debugUtils.reloadEverything},
        {"reload_scenes", debugUtils.reloadScenes},
        {"reload_tools", debugUtils.reloadTools},
        {"reload_entities", debugUtils.reloadEntities},
        {"reload_triggers", debugUtils.reloadTriggers},
        {"reload_effects", notYetImplementedNotification},
        {"reload_user_interface", reloadUI},
        {"reload_language_files", debugUtils.reloadLanguageFiles}
    }},
    {"redraw_map", debugUtils.redrawMap},
    {"test_console", debugUtils.debug}
}}

menubar.menubar = {
    {"file", {
        {"new", loadedState.newMap},
        {"open", loadedState.openMap},
        {"recent", notYetImplementedNotification},
        {},
        {"save", loadedState.saveCurrentMap},
        {"save_as", loadedState.saveAsCurrentMap},
        {},
        {"exit", love.event.quit}
    }},
    {"edit", {
        {"undo", history.undo},
        {"redo", history.redo},
        {},
        {"settings", notYetImplementedNotification}
    }},
    {"view", notYetImplementedNotification},
    {"map", {
        {"stylegrounds", notYetImplementedNotification},
        {"metadata", notYetImplementedNotification}
    }},
    {"room", {
        {"add", roomEditor.createNewRoom},
        {"configure", roomEditor.editExistingRoom},
        {},
        {"delete", deleteCurrentRoom}
    }},
    -- Only add if enabled
    addDebug and debugMenu or false,
    {"help", {
        {"check_for_updates", checkForUpdates},
        {"about", notYetImplementedNotification}
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
    addLanguageStrings(preparedMenubar, language)

    return uiElements.topbar(preparedMenubar)
end

return menubar