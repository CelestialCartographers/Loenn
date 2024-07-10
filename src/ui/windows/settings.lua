local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local settingsEditor = require("ui.settings_editor")
local configs = require("configs")
local config = require("utils.config")
local tabbedWindow = require("ui.widgets.tabbed_window")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "settings_window"

local settingsWindow = {}

-- TODO - Show default somewhere?

-- TODO - Some of these should probably be locked behind advanced settings
-- TODO - Add support for a "description" for the category

local defaultTabForms = {
    {
        title = "ui.settings_window.tab.general",
        groups = {
            {
                title = "ui.settings_window.group.general",
                fieldOrder = {
                    "celesteGameDirectory", "general.language",
                    "general.persistWindowFullScreen", "general.persistWindowPosition",
                    "general.persistWindowSize",
                }
            }
        }
    },
    {
        title = "ui.settings_window.tab.graphics",
        groups = {
            {
                title = "ui.settings_window.group.general",
                fieldOrder = {
                    "graphics.focusedDrawRate", "graphics.focusedMainLoopSleep",
                    "graphics.focusedUpdateRate", "graphics.unfocusedDrawRate",
                    "graphics.unfocusedMainLoopSleep", "graphics.unfocusedUpdateRate",
                    "graphics.vsync", "editor.displayFPS",
                }
            }
        }
    },
}

-- TODO - Remove once moved into tabs, this is a semi complete list of all settings
local defaultFieldGroups = {
    {
        title = "ui.settings_window.group.general",
        fieldOrder = {
            "celesteGameDirectory", "general.language",
            "general.persistWindowFullScreen", "general.persistWindowPosition",
            "general.persistWindowSize",
        }
    },
    {
        title = "ui.settings_window.group.backups",
        fieldOrder = {
            "backups.backupMode", "backups.backupRate",
            "backups.enabled", "backups.maximumFiles",
        }
    },
    {
        title = "ui.settings_window.group.debug",
        fieldOrder = {
            "debug.displayConsole", "debug.enableDebugOptions",
            "debug.logPluginLoading", "debug.loggingFlushImmediatelyLevel",
            "debug.loggingLevel",
        }
    },
    {
        title = "ui.settings_window.group.hotkeys",
        fieldOrder = {
            "hotkeys.cameraZoomIn", "hotkeys.cameraZoomOut",
            "hotkeys.debugMode", "hotkeys.debugRedrawMap",
            "hotkeys.debugReloadEntities", "hotkeys.debugReloadEverything",
            "hotkeys.debugReloadLuaInstance", "hotkeys.debugReloadTools",
            "hotkeys.itemSelectAll", "hotkeys.itemsCopy",
            "hotkeys.itemsCut", "hotkeys.itemsPaste",
            "hotkeys.itemsSelectAll", "hotkeys.new",
            "hotkeys.open", "hotkeys.redo",
            "hotkeys.roomAddNew", "hotkeys.roomConfigureCurrent",
            "hotkeys.roomDelete", "hotkeys.roomMoveDown",
            "hotkeys.roomMoveDownPrecise", "hotkeys.roomMoveLeft",
            "hotkeys.roomMoveLeftPrecise", "hotkeys.roomMoveRight",
            "hotkeys.roomMoveRightPrecise", "hotkeys.roomMoveUp",
            "hotkeys.roomMoveUpPrecise", "hotkeys.roomResizeDownGrow",
            "hotkeys.roomResizeDownShrink", "hotkeys.roomResizeLeftGrow",
            "hotkeys.roomResizeLeftShrink", "hotkeys.roomResizeRightGrow",
            "hotkeys.roomResizeRightShrink", "hotkeys.roomResizeUpGrow",
            "hotkeys.roomResizeUpShrink", "hotkeys.save",
            "hotkeys.saveAs", "hotkeys.toggleFullscreen",
            "hotkeys.undo",
        }
    },
    {
        title = "ui.settings_window.group.editor",
        fieldOrder = {
            "editor.alwaysRedrawUnselectedRooms", "editor.canvasMoveButton",
            "editor.checkDependenciesOnSave", "editor.contextMenuButton",
            "editor.copyUsesClipboard", "editor.displayFPS",
            "editor.historyEntryLimit", "editor.itemAddNode",
            "editor.itemAllowPixelPerfect", "editor.itemDelete",
            "editor.itemFlipHorizontal", "editor.itemFlipVertical",
            "editor.itemMoveDown", "editor.itemMoveLeft",
            "editor.itemMoveRight", "editor.itemMoveUp",
            "editor.itemResizeDownGrow", "editor.itemResizeDownShrink",
            "editor.itemResizeLeftGrow", "editor.itemResizeLeftShrink",
            "editor.itemResizeRightGrow", "editor.itemResizeRightShrink",
            "editor.itemResizeUpGrow", "editor.itemResizeUpShrink",
            "editor.itemRotateLeft", "editor.itemRotateRight",
            "editor.lazyLoadExternalAtlases", "editor.movementAxisBoundModifier",
            "editor.objectCloneButton", "editor.pasteCentered",
            "editor.precisionModifier", "editor.prepareRoomRenderInBackground",
            "editor.recentFilesEntryLimit", "editor.selectionAddModifier",
            "editor.sortRoomsOnSave", "editor.toolActionButton",
            "editor.toolsPersistUsingGroup", "editor.warnOnMissingEntityHandler",
            "editor.warnOnMissingTexture",
        }
    },
    {
        title = "ui.settings_window.group.graphics",
        fieldOrder = {
            "graphics.focusedDrawRate", "graphics.focusedMainLoopSleep",
            "graphics.focusedUpdateRate", "graphics.unfocusedDrawRate",
            "graphics.unfocusedMainLoopSleep", "graphics.unfocusedUpdateRate",
            "graphics.vsync",
        }
    },
}

local defaultFieldInformation = {
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
    ["hotkeys.itemSelectAll"] = {
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

    ["editor.toolActionButton"] = {
        fieldType = "mouse_button"
    },
    ["editor.objectCloneButton"] = {
        fieldType = "mouse_button"
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
    }
}

local settingsWindowGroup = uiElements.group({}):with({
    editSettings = settingsWindow.editSettings
})

local function prepareFormData()
    local data = rawget(configs, "data")

    print(utils.serialize(data))

    return utils.deepcopy(data)
end

local function saveSettings(formFields)
    -- TODO - Reload hotkeys

    local newSettings = form.getFormData(formFields)
    local oldSettings = rawget(configs, "data")

    utils.mergeTables(oldSettings, newSettings)

    rawset(configs, "data", newSettings)
    config.writeConfig(configs, true)
end

local function prepareTabForm(language, tabData, fieldInformation, formData, buttons)
    local tab = {}
    local fieldNames = {}

    local titleParts = tabData.title:split(".")()
    local titleLanguage = utils.getPath(language, titleParts)
    local title = tostring(titleLanguage)

    local fieldGroups = tabData.groups or {}

    for _, group in ipairs(fieldGroups) do
        -- Use title name as language path
        if group.title then
            local groupTitleParts = group.title:split(".")()
            local baseLanguage = utils.getPath(language, groupTitleParts)

            group.title = tostring(baseLanguage.name)
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

        fieldInformation[field].displayName = tostring(settingsAttributes[fieldLanguageKey])
        fieldInformation[field].tooltipText = tostring(settingsDescriptions[fieldLanguageKey])
    end

    local tabForm, tabFields = form.getForm(buttons, formData, {
        fields = fieldInformation,
        groups = fieldGroups,
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
    form.prepareScrollableWindow(window)
    form.addTitleChangeHandler(window, windowTitle, allFields)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function settingsWindow.getWindow()
    settingsEditor.settingsWindow = settingsWindow

    return settingsWindowGroup
end

return settingsWindow