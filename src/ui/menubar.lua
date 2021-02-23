local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local history = require("history")
local debugUtils = require("debug_utils")

local utils = require("utils")
local languageRegistry = require("language_registry")

local roomEditor = require("ui.room_editor")

local menubar = {}

menubar.menubar = {
    {"file", {
        {"new"},
        {"open", loadedState.openMap},
        {"recent", {}},
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
        {"settings"}
    }},
    {"view", {

    }},
    {"map", {
        {"stylegrounds"},
        {"metadata"}
    }},
    {"room", {
        {"add", roomEditor.createNewRoom},
        {"configure", roomEditor.editExistingRoom},
        {},
        {"delete"}
    }},
    {"debug", {
        {"reload", {
            {"reload_everything", debugUtils.reloadEverything},
            {"reload_scenes", debugUtils.reloadScenes},
            {"reload_tools", debugUtils.reloadTools},
            {"reload_entities", debugUtils.reloadEntities},
            {"reload_triggers", debugUtils.reloadTriggers},
            {"reload_effects"},
            {"reload_user_interface", function() debugUtils.reloadUI() end}, -- debugUtils.reloadUI might change, call in function
            {"reload_language_files", debugUtils.reloadLanguageFiles}
        }},
        {"redraw_map", debugUtils.redrawMap},
        {"test_console", debugUtils.debug}
    }},
    {"help", {
        {"check_for_updates"},
        {"about"}
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

function menubar.getMenubar()
    local preparedMenubar = utils.deepcopy(menubar.menubar)
    local language = languageRegistry.getLanguage()

    addLanguageStrings(preparedMenubar, language)

    return uiElements.topbar(preparedMenubar)
end

return menubar