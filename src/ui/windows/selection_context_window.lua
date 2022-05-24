local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local form = require("ui.forms.form")
local snapshotUtils = require("snapshot_utils")
local history = require("history")
local viewportHandler = require("viewport_handler")
local layerHandlers = require("layer_handlers")
local toolUtils = require("tool_utils")
local notifications = require("ui.notification")
local formUtils = require("ui.utils.forms")

local contextWindow = {}

local contextGroup
local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

local function editorSelectionContextMenuCallback(group, selections)
    contextWindow.createContextMenu(selections)
end

local function contextWindowUpdate(orig, self, dt)
    orig(self, dt)

    windowPreviousX = self.x
    windowPreviousY = self.y
end

local function getWindowTitle(language, selections, targetItem, targetLayer)
    local baseTitle = tostring(language.ui.selection_context_window.title)
    local titleParts = {baseTitle}

    if targetLayer == "entities" or targetLayer == "triggers" then
        -- Add entity/trigger name
        table.insert(titleParts, targetItem._name)

        -- Add id for selected items
        local ids = {}

        for _, selection in ipairs(selections) do
            local selectionId = selection.item._id
            local selectionLayer = selection.layer

            if selectionLayer == "entities" or selectionLayer == "trigers" then
                if selectionId then
                    table.insert(ids, tostring(selectionId))
                end
            end
        end

        if #ids > 0 then
            table.insert(titleParts, string.format("ID: %s", table.concat(ids, ", ")))
        end
    end

    return table.concat(titleParts, " - ")
end

-- TODO - Add history support
function contextWindow.saveChangesCallback(selections, dummyData)
    return function(formFields)
        local redraw = {}
        local newData = form.getFormData(formFields)
        local room = loadedState.getSelectedRoom()

        for _, selection in ipairs(selections) do
            local layer = selection.layer
            local item = selection.item

            -- Apply nil values from new data
            for k, v in pairs(dummyData) do
                if newData[k] == nil then
                    item[k] = nil
                end
            end

            for k, v in pairs(newData) do
                item[k] = v
            end

            redraw[layer] = true
        end

        if room then
            for layer, _ in pairs(redraw) do
                toolUtils.redrawTargetLayer(room, layer)
            end
        end
    end
end

local function prepareFormData(layer, item, language)
    local handler = layerHandlers.getHandler(layer)

    return formUtils.prepareFormData(handler, item, {}, {layer, item})
end

function contextWindow.createContextMenu(selections)
    local targetSelection = selections[1]
    local targetItem = targetSelection.item
    local targetLayer = targetSelection.layer

    local window
    local windowX = windowPreviousX
    local windowY = windowPreviousY
    local language = languageRegistry.getLanguage()

    -- TODO - Remove this once we support multiple selection editing
    if #selections > 1 then
        notifications.notify(tostring(language.ui.selection_context_window.multiple_selections))

        return
    end

    -- Don't stack windows on top of each other
    if #activeWindows > 0 then
        windowX, windowY = 0, 0
    end

    local dummyData, fieldInformation, fieldOrder = prepareFormData(targetLayer, targetItem, language)
    local buttons = {
        {
            text = tostring(language.ui.room_window.save_changes),
            formMustBeValid = true,
            callback = contextWindow.saveChangesCallback(selections, dummyData)
        }
    }

    local windowTitle = getWindowTitle(language, selections, targetItem, targetLayer)
    local selectionForm = form.getForm(buttons, dummyData, {
        fields = fieldInformation,
        fieldOrder = fieldOrder
    })

    window = uiElements.window(windowTitle, selectionForm):with({
        x = windowX,
        y = windowY,

        updateHidden = true
    }):hook({
        update = contextWindowUpdate
    })

    table.insert(activeWindows, window)
    contextGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function contextWindow.getWindow()
    contextGroup = uiElements.group({}):with({
        editorSelectionContextMenu = editorSelectionContextMenuCallback
    })

    return contextGroup
end

return contextWindow