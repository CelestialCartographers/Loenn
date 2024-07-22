local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local settingsEditor = require("ui.settings_editor")
local configs = require("configs")
local defaultConfigData = require("default_config")
local config = require("utils.config")
local tabbedWindow = require("ui.widgets.tabbed_window")
local startup = require("initial_startup")
local themes = require("ui.themes")
local debugUtils = require("debug_utils")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "settings_window"

local settingsWindow = {}

local defaultTabForms = {
    {
        title = "ui.settings_window.tab.general",
        groups = {
            {
                title = "ui.settings_window.group.general.startup",
                fieldOrder = {
                    "celesteGameDirectory",
                    "spacer",
                    "general.persistWindowFullscreen",
                    "general.persistWindowPosition",
                    "general.persistWindowSize"
                }
            },
            {
                title = "ui.settings_window.group.general.files",
                fieldOrder = {
                    "editor.recentFilesEntryLimit",
                    "spacer",
                    "editor.checkDependenciesOnSave",
                    "editor.sortRoomsOnSave",
                }
            },
            {
                title = "ui.settings_window.group.general.backups",
                fieldOrder = {
                    "backups.enabled",
                    "spacer",
                    "backups.backupRate",
                    "backups.maximumFiles",
                }
            }
        }
    },
    {
        title = "ui.settings_window.tab.editor",
        groups = {
            {
                title = "ui.settings_window.group.editor.interface",
                fieldOrder = {
                    "ui.theme.themeName",
                    "spacer",
                    "ui.lists.shrinkToFit",
                }
            },
            {
                title = "ui.settings_window.group.editor.clipboard",
                fieldOrder = {
                    "editor.copyUsesClipboard",
                    "editor.pasteCentered",
                }
            },
            {
                title = "ui.settings_window.group.editor.tools",
                fieldOrder = {
                    "editor.toolsPersistUsingGroup"
                }
            },
            {
                title = "ui.settings_window.group.editor.triggers",
                fieldOrder = {
                    "editor.triggersTrimModName",
                    "editor.triggersUseCategoryColors",
                }
            },
            {
                title = "ui.settings_window.group.editor.search",
                fieldOrder = {
                    "ui.searching.searchCaseSensitive",
                    "spacer",
                    "ui.searching.searchFuzzy",
                    "ui.searching.sortByScore"
                }
            }
        },
    },
    {
        title = "ui.settings_window.tab.hotkeys",
        groups = {
            {
                title = "ui.settings_window.group.hotkeys.general",
                fieldOrder = {
                    "hotkeys.new",
                    "hotkeys.open",
                    "hotkeys.save",
                    "hotkeys.saveAs",
                    "hotkeys.undo",
                    "hotkeys.redo",
                    "hotkeys.toggleFullscreen"
                }
            },
            {
                title = "ui.settings_window.group.hotkeys.map_view",
                fieldOrder = {
                    "editor.toolActionButton",
                    "editor.canvasMoveButton",
                    "editor.contextMenuButton",
                    "spacer",
                    "hotkeys.cameraZoomIn",
                    "hotkeys.cameraZoomOut"
                }
            },
            {
                title = "ui.settings_window.group.hotkeys.selections",
                fieldOrder = {
                    "hotkeys.itemsCopy",
                    "hotkeys.itemsCut",
                    "hotkeys.itemsPaste",
                    "editor.selectionAddModifier",
                    "hotkeys.itemsSelectAll",
                    "hotkeys.itemsDeselect",
                    "editor.itemAddNode",
                    "spacer",
                    "editor.objectCloneButton",
                    "editor.itemDelete",
                    "editor.itemFlipHorizontal",
                    "editor.itemFlipVertical",
                    "editor.itemRotateLeft",
                    "editor.itemRotateRight",
                    "editor.precisionModifier",
                    "editor.movementAxisBoundModifier",
                    "editor.itemMoveUp",
                    "editor.itemMoveDown",
                    "editor.itemMoveLeft",
                    "editor.itemMoveRight",
                    "editor.itemResizeUpGrow",
                    "editor.itemResizeDownGrow",
                    "editor.itemResizeLeftGrow",
                    "editor.itemResizeRightGrow",
                    "editor.itemResizeUpShrink",
                    "editor.itemResizeDownShrink",
                    "editor.itemResizeLeftShrink",
                    "editor.itemResizeRightShrink"
                }
            },
            {
                title = "ui.settings_window.group.hotkeys.rooms",
                fieldOrder = {
                    "hotkeys.roomAddNew",
                    "hotkeys.roomDelete",
                    "hotkeys.roomConfigureCurrent",
                    "spacer",
                    "hotkeys.roomMoveUp",
                    "hotkeys.roomMoveDown",
                    "hotkeys.roomMoveLeft",
                    "hotkeys.roomMoveRight",
                    "hotkeys.roomResizeUpGrow",
                    "hotkeys.roomResizeDownGrow",
                    "hotkeys.roomResizeLeftGrow",
                    "hotkeys.roomResizeRightGrow",
                    "hotkeys.roomResizeUpShrink",
                    "hotkeys.roomResizeDownShrink",
                    "hotkeys.roomResizeLeftShrink",
                    "hotkeys.roomResizeRightShrink"
                }
            },
            {
                title = "ui.settings_window.group.hotkeys.lists",
                fieldOrder = {
                    "ui.searching.searchPreviousResultKey",
                    "ui.searching.searchNextResultKey",
                    "ui.searching.searchRearrangeModifier"
                }
            },
            {
                title = "ui.settings_window.group.hotkeys.search",
                fieldOrder = {
                    "ui.searching.searchExitKey",
                    "ui.searching.searchExitAndClearKey",
                    "ui.searching.searchSelectKey",
                    "ui.hotkeys.focusMaterialSearch"
                }
            },
            {
                title = "ui.settings_window.group.hotkeys.debug",
                fieldOrder = {
                    "hotkeys.debugReloadEntities",
                    "hotkeys.debugRedrawMap",
                    "hotkeys.debugReloadTools",
                    "spacer",
                    "hotkeys.debugReloadEverything",
                    "hotkeys.debugReloadLuaInstance",
                }
            },
        }
    },
    {
        title = "ui.settings_window.tab.graphics",
        fieldOrder = {
            "editor.displayFPS",
            "graphics.vsync",
            "spacer",
            "editor.alwaysRedrawUnselectedRooms",
            "editor.lazyLoadExternalAtlases",
            "editor.prepareRoomRenderInBackground",
            -- TODO - Implement these options as a dropdown
            -- "graphics.focusedDrawRate",
            -- "graphics.focusedMainLoopSleep",
            -- "graphics.focusedUpdateRate",
            -- "graphics.unfocusedDrawRate",
            -- "graphics.unfocusedMainLoopSleep",
            -- "graphics.unfocusedUpdateRate",
        }
    },
    {
        title = "ui.settings_window.tab.debug",
        fieldOrder = {
            "debug.enableDebugOptions",
            "debug.displayConsole",
            "spacer",
            "debug.logPluginLoading",
            "editor.warnOnMissingEntityHandler",
            "editor.warnOnMissingTexture"
        }
    },
}

local themeOptions = {}

for themeName, theme in pairs(themes.themes) do
    table.insert(themeOptions, themeName)
end

local defaultFieldInformation = {
    ["spacer"] = {
        fieldType = "spacer"
    },

    ["celesteGameDirectory"] = {
        fieldType = "path",
        filePickerExtensions = {"exe", "dll", "app"},
        allowEmpty = false,
        allowMissingPath = true,
        relativeToMod = false,
        useUnixSeparator = false,
        earlyValidator = function(filename)
            return startup.verifyCelesteDir(filename)
        end,
        filenameProcessor = function(filename)
            return startup.cleanupPath(filename)
        end,
    },

    ["hotkeys.cameraZoomIn"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.cameraZoomOut"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.debugMode"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.debugRedrawMap"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.debugReloadEntities"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.debugReloadEverything"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.debugReloadLuaInstance"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.debugReloadTools"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.itemsCopy"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.itemsCut"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.itemsPaste"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.itemsSelectAll"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.itemsDeselect"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.new"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.open"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.redo"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomAddNew"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomConfigureCurrent"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomDelete"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveDown"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveDownPrecise"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveLeft"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveLeftPrecise"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveRight"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveRightPrecise"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveUp"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomMoveUpPrecise"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeDownGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeDownShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeLeftGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeLeftShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeRightGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeRightShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeUpGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.roomResizeUpShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.save"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.saveAs"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.toggleFullscreen"] = {
        fieldType = "keyboard_hotkey"
    },
    ["hotkeys.undo"] = {
        fieldType = "keyboard_hotkey"
    },

    ["backups.backupRate"] = {
        fieldType = "integer",
        minimumValue = 15,
    },
    ["backups.maximumFiles"] = {
        fieldType = "integer",
        minimumValue = 1,
    },

    ["editor.recentFilesEntryLimit"] = {
        fieldType = "integer",
        minimumValue = 0,
    },
    ["editor.canvasMoveButton"] = {
        fieldType = "mouse_button"
    },
    ["editor.contextMenuButton"] = {
        fieldType = "mouse_button"
    },
    ["editor.toolActionButton"] = {
        fieldType = "mouse_button"
    },
    ["editor.objectCloneButton"] = {
        fieldType = "mouse_button"
    },
    ["editor.selectionAddModifier"] = {
        fieldType = "keyboard_modifier"
    },
    ["editor.precisionModifier"] = {
        fieldType = "keyboard_modifier"
    },
    ["editor.movementAxisBoundModifier"] = {
        fieldType = "keyboard_modifier"
    },
    ["editor.itemAddNode"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemDelete"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemFlipHorizontal"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemFlipVertical"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemMoveDown"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemMoveLeft"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemMoveRight"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemMoveUp"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeDownGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeDownShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeLeftGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeLeftShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeRightGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeRightShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeUpGrow"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemResizeUpShrink"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemRotateLeft"] = {
        fieldType = "keyboard_hotkey"
    },
    ["editor.itemRotateRight"] = {
        fieldType = "keyboard_hotkey"
    },

    ["debug.loggingFlushImmediatelyLevel"] = {
        fieldType = "integer"
    },
    ["debug.loggingLevel"] = {
        fieldType = "integer"
    },

    ["ui.searching.searchExitAndClearKey"] = {
        fieldType = "keyboard_hotkey"
    },
    ["ui.searching.searchExitKey"] = {
        fieldType = "keyboard_hotkey"
    },
    ["ui.searching.searchSelectKey"] = {
        fieldType = "keyboard_hotkey"
    },
    ["ui.searching.searchNextResultKey"] = {
        fieldType = "keyboard_hotkey"
    },
    ["ui.searching.searchPreviousResultKey"] = {
        fieldType = "keyboard_hotkey"
    },
    ["ui.searching.searchRearrangeModifier"] = {
        fieldType = "keyboard_modifier"
    },
    ["ui.searching.searchCaseSensitive"] = {
        fieldType = "string",
        editable = false,
        options = {
            -- TODO - Translate with language file
            {"Contextual", "contextual"},
            {"Always", "always"},
            {"Never", "never"}
        }
    },
    ["ui.theme.themeName"] = {
        fieldType = "string",
        editable = false,
        options = themeOptions
    },

    ["ui.hotkeys.focusMaterialSearch"] = {
        fieldType = "keyboard_hotkey"
    },
}

local settingsWindowGroup = uiElements.group({}):with({
    editSettings = settingsWindow.editSettings
})

local function prepareFormData()
    local data = rawget(configs, "data")

    return utils.deepcopy(data)
end

local function applyNewSettings(newSettings, oldSettings)
    local function settingChanged(key)
        local parts = $(key):split(".")()

        return utils.getPath(newSettings, parts) ~= utils.getPath(oldSettings, parts)
    end

    if settingChanged("ui.theme.themeName") then
        themes.useTheme(newSettings.ui.theme.themeName)
    end

    if settingChanged("editor.triggersTrimModName") or settingChanged("editor.triggersUseCategoryColors") then
        debugUtils.redrawMap()
    end

    -- Reload hotkeys, tools and libraries
    -- These are the only things that should (hopefully) add hotkeys
    debugUtils.reloadHotkeys()
    debugUtils.reloadTools()
    debugUtils.reloadLibraries()
end

local function saveSettings(formFields)

    local newSettings = form.getFormData(formFields)
    local oldSettings = rawget(configs, "data")

    utils.mergeTables(oldSettings, newSettings)

    rawset(configs, "data", newSettings)
    config.writeConfig(configs, true)

    applyNewSettings(newSettings, oldSettings)
end

local function prepareTabForm(language, tabData, fieldInformation, formData, buttons)
    local tab = {}
    local fieldNames = {}

    local titleParts = tabData.title:split(".")()
    local titleLanguage = utils.getPath(language, titleParts)
    local title = tostring(titleLanguage)

    local fieldGroups = tabData.groups
    local fieldOrder = tabData.fieldOrder

    for _, name in ipairs(fieldOrder or {}) do
        table.insert(fieldNames, name)
    end

    for _, group in ipairs(fieldGroups or {}) do
        -- Use title name as language path
        if group.title then
            local groupTitleParts = group.title:split(".")()
            local groupLanguageName = utils.getPath(language, groupTitleParts)

            group.title = tostring(groupLanguageName)
        end

        for _, name in ipairs(group.fieldOrder) do
            table.insert(fieldNames, name)
        end
    end

    for _, field in ipairs(fieldNames) do
        if not fieldInformation[field] then
            fieldInformation[field] = {}
        end

        local baseLanguage = language.settings
        local nameParts = form.getNameParts(field)
        local fieldLanguageKey = nameParts[#nameParts]

        -- Go down every part besides the last
        for i = 1, #nameParts - 1 do
            baseLanguage = baseLanguage[nameParts[i]]
        end

        local settingsAttributes = baseLanguage.attribute
        local settingsDescriptions = baseLanguage.description

        local displayName = tostring(settingsAttributes[fieldLanguageKey])
        local tooltipText = tostring(settingsDescriptions[fieldLanguageKey])

        local fieldDefault = utils.getPath(defaultConfigData, nameParts)

        if fieldDefault then
            local settingsWindowLanguage = language.ui.settings_window
            local defaultFormatString = tostring(settingsWindowLanguage.defaultTooltipFormat)

            if type(fieldDefault) == "boolean" then
                fieldDefault = fieldDefault and tostring(settingsWindowLanguage.defaultValueEnabled) or tostring(settingsWindowLanguage.defaultValueDisabled)
            end

            tooltipText = string.format(defaultFormatString, tooltipText, fieldDefault)
        end

        fieldInformation[field].displayName = displayName
        fieldInformation[field].tooltipText = tooltipText
    end

    local tabForm, tabFields = form.getForm(buttons, formData, {
        fields = fieldInformation,
        groups = fieldGroups,
        fieldOrder = fieldOrder,
        ignoreUnordered = true,
    })

    tab.title = title
    tab.content = tabForm
    tab.fields = tabFields
    tab.fieldNames = fieldNames

    return tab
end

function settingsWindow.editSettings()
    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.settings_window.window_title)

    local formData = prepareFormData()
    local fieldInformation = utils.deepcopy(defaultFieldInformation)

    local tabs = {}
    local allFields = {}

    local buttons = {
        {
            text = tostring(language.ui.settings_window.save_changes),
            formMustBeValid = true,
            callback = function()
                saveSettings(allFields)
            end
        }
    }

    for _, tabData in ipairs(defaultTabForms) do
        local tab = prepareTabForm(language, utils.deepcopy(tabData), fieldInformation, formData, buttons)

        table.insert(tabs, tab)
    end

    for _, tab in ipairs(tabs) do
        for _, field in ipairs(tab.fields) do
            table.insert(allFields, field)
        end
    end

    local window = tabbedWindow.createWindow(windowTitle, tabs)
    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)

    windowPersister.trackWindow(windowPersisterName, window)
    settingsWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    widgetUtils.preventOutOfBoundsMovement(window)
    tabbedWindow.prepareScrollableWindow(window)
    form.addTitleChangeHandler(window, windowTitle, allFields)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function settingsWindow.getWindow()
    settingsEditor.settingsWindow = settingsWindow

    return settingsWindowGroup
end

return settingsWindow