local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local utils = require("utils")
local form = require("ui.forms.form")
local configs = require("configs")
local enums = require("consts.celeste_enums")
local stylegroundEditor = require("ui.styleground_editor")
local listWidgets = require("ui.widgets.lists")
local formHelper = require("ui.forms.form")

local stylegroundWindow = {}

local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

local stylegroundWindowGroup = uiElements.group({}):with({

})

local function getWindowContent(map)
    local layout = uiElements.label("Work in progress")

    return layout
end

function stylegroundWindow.editStylegrounds(map)
    local window
    local layout = getWindowContent(map)

    window = uiElements.window("Styleground Window", layout):with({
        width = 600,
        height = 600
    })

    table.insert(activeWindows, window)
    stylegroundWindowGroup.parent:addChild(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function stylegroundWindow.getWindow()
    stylegroundEditor.stylegroundWindow = stylegroundWindow

    return stylegroundWindowGroup
end

return stylegroundWindow