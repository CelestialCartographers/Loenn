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

local contextWindow = {}

local contextGroup
local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

-- Remove values that would very want to be exposed for any type of selection item
local globallyFilteredKeys = {
    _type = true
}

local function editorSelectionContextMenuCallback(group, selections)
    contextWindow.createContextMenu(selections)
end

local function contextWindowUpdate(orig, self, dt)
    orig(self, dt)

    windowPreviousX = self.x
    windowPreviousY = self.y
end

local function getItemIgnoredFields(layer, item)
    local handler = layerHandlers.getHandler(layer)
    local ignored = handler.ignoredFields and handler.ignoredFields(layer, item) or {}
    local ignoredSet = {}

    for _, name in ipairs(ignored) do
        ignoredSet[name] = true
    end

    return ignoredSet
end

local function getItemFieldOrder(layer, item)
    local handler = layerHandlers.getHandler(layer)
    local fieldOrder = handler.fieldOrder and handler.fieldOrder(layer, item) or {}

    return utils.deepcopy(fieldOrder)
end

local function getItemFieldInformation(layer, item)
    local handler = layerHandlers.getHandler(layer)
    local fieldInformation = handler.fieldInformation and handler.fieldInformation(layer, item) or {}

    return utils.deepcopy(fieldInformation)
end

local function getItemLanguage(layer, item, language)
    local handler = layerHandlers.getHandler(layer)

    if handler and handler.languageData then
        local itemLanguage, fallbackLanguage = handler.languageData(layer, item, language)

        return itemLanguage, fallbackLanguage or itemLanguage

    else
        return language, language
    end
end

local function getLanguageKey(key, language, default)
    if language[key]._exists then
        return tostring(language[key])
    end

    return default
end

-- TODO - Add history support
function contextWindow.saveChangesCallback(selections)
    return function(formFields)
        local redraw = {}
        local newData = form.getFormData(formFields)
        local room = loadedState.getSelectedRoom()

        for _, selection in ipairs(selections) do
            local layer = selection.layer
            local item = selection.item

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

function contextWindow.prepareFormData(layer, item, language)
    local dummyData = {}

    local fieldsAdded = {}
    local fieldInformation = getItemFieldInformation(layer, item)
    local fieldOrder = getItemFieldOrder(layer, item)
    local fieldIgnored = getItemIgnoredFields(layer, item)

    local fieldLanguage, fallbackLanguage = getItemLanguage(layer, item, language)
    local languageTooltips = fieldLanguage.description
    local languageAttributes = fieldLanguage.attribute
    local fallbackTooltips = fallbackLanguage.description
    local fallbackAttributes = fallbackLanguage.attribute

    for _, field in ipairs(fieldOrder) do
        local value = item[field]

        if value ~= nil then
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageAttributes, getLanguageKey(field, fallbackAttributes, humanizedName))
            local tooltip = getLanguageKey(field, languageTooltips, getLanguageKey(field, fallbackTooltips))

            if not fieldInformation[field] then
                fieldInformation[field] = {}
            end

            fieldsAdded[field] = true
            dummyData[field] = utils.deepcopy(value)
            fieldInformation[field].displayName = displayName
            fieldInformation[field].tooltipText = tooltip
        end
    end

    for field, value in pairs(item) do
        -- Some fields should not be exposed automatically
        -- Any fields already added should not be added again
        if not globallyFilteredKeys[field] and not fieldIgnored[field] and not fieldsAdded[field] then
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageAttributes, humanizedName)
            local tooltip = getLanguageKey(field, languageTooltips)

            table.insert(fieldOrder, field)

            if not fieldInformation[field] then
                fieldInformation[field] = {}
            end

            dummyData[field] = utils.deepcopy(value)
            fieldInformation[field].displayName = displayName
            fieldInformation[field].tooltipText = tooltip
        end
    end

    return dummyData, fieldInformation, fieldOrder
end

function contextWindow.createContextMenu(selections)
    local targetSelection = selections[1]
    local targetItem = targetSelection.item
    local targetLayer = targetSelection.layer

    local window
    local windowX = windowPreviousX
    local windowY = windowPreviousY
    local language = languageRegistry.getLanguage()

    -- Don't stack windows on top of each other
    if #activeWindows > 0 then
        windowX, windowY = 0, 0
    end

    local dummyData, fieldInformation, fieldOrder = contextWindow.prepareFormData(targetLayer, targetItem, language)
    local buttons = {
        {
            text = tostring(language.ui.room_window.save_changes),
            formMustBeValid = true,
            callback = contextWindow.saveChangesCallback(selections)
        },
        {
            text = tostring(language.ui.room_window.close_window),
            callback = function(formFields)
                for i, w in ipairs(activeWindows) do
                    if w == window then
                        table.remove(activeWindows, i)
                        widgetUtils.focusMainEditor()

                        break
                    end
                end

                window:removeSelf()
            end
        }
    }

    local windowTitle = tostring(language.ui.selection_context_window.title)
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