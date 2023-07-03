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
local fileLocations = require("file_locations")
local filesystem = require("utils.filesystem")
local mapImageGenerator = require("map_image")
local persistence = require("persistence")
local mods = require("mods")

local utils = require("utils")
local languageRegistry = require("language_registry")

local roomEditor = require("ui.room_editor")
local stylegroundEditor = require("ui.styleground_editor")
local metadataEditor = require("ui.metadata_editor")
local dependencyEditor = require("ui.dependency_editor")
local aboutWindow = require("ui.about_window_wrapper")

local activeMenubar

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

local function openStorageDirectory()
    local fileUrl = string.format("file://%s", fileLocations.getStorageDir())

    love.system.openURL(fileUrl)
end

local function saveMapImage()
    filesystem.saveDialog(loadedState.filename, "png", function(filename)
        local saved = mapImageGenerator.saveMapImage(filename)

        if not saved then
            local language = languageRegistry.getLanguage()
            local text = tostring(language.ui.notifications.mapImageSaveFailed)

            notifications.notify(text, -1)
        end
    end)
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

local function toggleOnlyShowDependencies()
    loadedState.setShowDependendedOnMods(not loadedState.onlyShowDependedOnMods)
end

local function getOnlyShowDependencies()
    return loadedState.onlyShowDependedOnMods
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
        {"reload_effects", debugUtils.reloadEffects},
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
        {"view_layer", {
            {"view_tiles_fg", getLayerToggleFunction("tilesFg"), "checkbox", getLayerValueFunction("tilesFg")},
            {"view_tiles_bg", getLayerToggleFunction("tilesBg"), "checkbox", getLayerValueFunction("tilesBg")},
            {"view_entities", getLayerToggleFunction("entities"), "checkbox", getLayerValueFunction("entities")},
            {"view_triggers", getLayerToggleFunction("triggers"), "checkbox", getLayerValueFunction("triggers")},
            {"view_decals_fg", getLayerToggleFunction("decalsFg"), "checkbox", getLayerValueFunction("decalsFg")},
            {"view_decals_bg", getLayerToggleFunction("decalsBg"), "checkbox", getLayerValueFunction("decalsBg")},
        }},
        {"view_only_depended_on", toggleOnlyShowDependencies, "checkbox", getOnlyShowDependencies},
    }},
    {"map", {
        {"stylegrounds", stylegroundEditor.editStylegrounds},
        {"metadata", metadataEditor.editMetadata},
        {"dependencies", dependencyEditor.editDependencies},
        {"save_map_image", saveMapImage},
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
        {"open_storage_directory", openStorageDirectory},
        {"about", aboutWindow.showAboutWindow}
    }}
}

local function findMenuEntry(menu, key)
    if not menu then
        return
    end

    for _, entry in ipairs(menu) do
        if entry[1] == key or entry._key == key then
            return entry
        end
    end
end

-- TODO - Tooltip support
local function addLanguageStrings(menu, language)
    if utils.typeof(menu) == "table" then
        local languageKey = menu[1]
        local languageKeyType = type(languageKey)

        if languageKeyType == "string" then
            menu[1] = tostring(language.ui.menubar[languageKey])
            menu._key = languageKey
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

local function addRecentFiles(menu)
    local recentFiles = persistence.recentFiles or {}
    local fileEntry = findMenuEntry(menu, "file") or {}
    local recentEntry = findMenuEntry(fileEntry[2], "recent")

    if recentEntry then
        local recentChildren = {}

        for _, filename in ipairs(recentFiles) do
            local cleanedFilename = filename
            local modPath = mods.getFilenameModPath(filename)

            -- If packaged
            if modPath then
                local relativeTo = utils.joinpath(modPath, "Maps")

                cleanedFilename = string.sub(filename, #relativeTo + 2)
                cleanedFilename = utils.stripExtension(cleanedFilename)

            else
                cleanedFilename = utils.stripExtension(filesystem.filename(filename))
            end

            table.insert(recentChildren, {
                cleanedFilename,
                function()
                    loadedState.loadFile(filename)
                end
            })
        end

        recentEntry[2] = recentChildren
    end
end

local function hotswapMenubar()
    local newMenubar = menubar.getMenubar()

    activeMenubar.children = newMenubar.children
    activeMenubar:reflow()
    activeMenubar:repaint()
end

function menubar.getMenubar()
    local preparedMenubar = utils.deepcopy(menubar.menubar)
    local language = languageRegistry.getLanguage()

    removeFalseEntries(preparedMenubar)
    addLanguageStrings(preparedMenubar, language)
    addRecentFiles(preparedMenubar)
    wrapInSubmenuClosers(preparedMenubar)
    handleElementTypes(preparedMenubar)

    local topbar = uiElements.topbar(preparedMenubar)

    topbar:hook({
        editorMapLoaded = function()
            hotswapMenubar()
        end
    })

    if not activeMenubar then
        activeMenubar = topbar
    end

    return topbar
end

return menubar