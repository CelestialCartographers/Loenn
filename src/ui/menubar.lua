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

local function getLayerToggleFunction(layer)
    return function()
        loadedState.setLayerVisible(layer, not loadedState.getLayerVisible(layer))
    end
end

local function getLayerValueFunction(layer)
    return function()
        return loadedState.getLayerVisible(layer) ~= false
    end
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

-- Tree of menubar items
-- First element is translation key
-- Second element is a sub tree or a function callback
-- Third is whether element type, by default it is plain text
-- Any following elements are up to the element type to handle
-- Closes by default, some menu items might not want to close the menu, for example "View" toggles
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
    {"view", {
        {"view_tiles_fg", getLayerToggleFunction("tilesFg"), "checkbox", getLayerValueFunction("tilesFg")},
        {"view_tiles_bg", getLayerToggleFunction("tilesBg"), "checkbox", getLayerValueFunction("tilesBg")},
        {"view_entities", getLayerToggleFunction("entities"), "checkbox", getLayerValueFunction("entities")},
        {"view_triggers", getLayerToggleFunction("triggers"), "checkbox", getLayerValueFunction("triggers")},
        {"view_decals_fg", getLayerToggleFunction("decalsFg"), "checkbox", getLayerValueFunction("decalsFg")},
        {"view_decals_bg", getLayerToggleFunction("decalsBg"), "checkbox", getLayerValueFunction("decalsBg")},
    }},
    {"map", {
        {"stylegrounds", stylegroundEditor.editStylegrounds},
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

-- TODO - Tooltip support
local function addLanguageStrings(menu, language)
    if utils.typeof(menu) == "table" then
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
    if utils.typeof(menu) == "table" then
        local callback = menu[2]
        local elementType = menu[3]
        local shouldCloseMenu = true
        local callbackType = type(callback)

        if elementType == "checkbox" then
            shouldCloseMenu = false
        end

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

-- No element type means it is plain text
-- Only other supported type is currently checkboxes
local function handleElementTypes(menu)
    if utils.typeof(menu) == "table" then
        local elementType = menu[3]

        if elementType == "checkbox" then
            local visibilityFunction = menu[4]
            local initialValue = true

            if visibilityFunction then
                initialValue = visibilityFunction()
            end

            menu[1] = uiElements.checkbox(menu[1], initialValue):hook({
                update = function(orig, self, dt)
                    orig(self, dt)

                    if visibilityFunction then
                        local newValue = visibilityFunction()

                        if self.value ~= newValue then
                            self.value = newValue
                        end
                    end
                end
            })
        end

        for _, sub in pairs(menu) do
            handleElementTypes(sub)
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
    handleElementTypes(preparedMenubar)

    return uiElements.topbar(preparedMenubar)
end

return menubar