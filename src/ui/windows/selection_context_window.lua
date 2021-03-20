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

    return fieldOrder
end

local function getItemLanguage(layer, item, language)
    local handler = layerHandlers.getHandler(layer)
    local itemLanguage = handler.languageData and handler.languageData(layer, item, language) or language

    return itemLanguage
end

local function getLanguageKey(key, language, default)
    if language[key]._exists then
        return tostring(language[key])
    end

    return default
end

local function saveChangesCallback(selections)
    return function(data)
        -- TODO - Make history snapshot and apply data
    end
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

    local dummyData = {}

    local fieldInformation = {}
    local fieldsAdded = {}
    local fieldOrder = getItemFieldOrder(targetLayer, targetItem)
    local fieldIgnored = getItemIgnoredFields(targetLayer, targetItem)

    local fieldLanguage = getItemLanguage(targetLayer, targetItem, language)
    local languageTooltips = fieldLanguage.description
    local languageAttributes = fieldLanguage.attribute

    for _, field in ipairs(fieldOrder) do
        local value = targetItem[field]

        if value ~= nil then
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageAttributes, humanizedName)
            local tooltip = getLanguageKey(field, languageTooltips)

            fieldsAdded[field] = true
            dummyData[field] = utils.deepcopy(value)
            fieldInformation[field] = {
                displayName = displayName,
                tooltipText = tooltip
            }
        end
    end

    for field, value in pairs(targetItem) do
        -- Some fields should not be exposed automatically
        -- Any fields already added should not be added again
        if not globallyFilteredKeys[field] and not fieldIgnored[field] and not fieldsAdded[field] then
            local humanizedName = utils.humanizeVariableName(field)
            local displayName = getLanguageKey(field, languageAttributes, humanizedName)
            local tooltip = getLanguageKey(field, languageTooltips)

            table.insert(fieldOrder, field)

            dummyData[field] = utils.deepcopy(value)
            fieldInformation[field] = {
                displayName = displayName,
                tooltipText = tooltip
            }
        end
    end

    local buttons = {
        {
            text = tostring(language.ui.room_window.save_changes),
            formMustBeValid = true,
            callback = saveChangesCallback(selections)
        },
        {
            text = tostring(language.ui.room_window.close_window),
            callback = function(formFields)
                for i, w in ipairs(activeWindows) do
                    if w == window then
                        table.remove(activeWindows, i)

                        break
                    end
                end

                window:removeSelf()
            end
        }
    }

    local windowTitle = tostring(language.ui.selection_context_window.title)
    local roomForm = form.getForm(buttons, dummyData, {
        fields = fieldInformation,
        fieldOrder = fieldOrder
    })

    window = uiElements.window(windowTitle, roomForm):with({
        x = windowX,
        y = windowY,

        updateHidden = true
    }):hook({
        update = contextWindowUpdate
    })

    table.insert(activeWindows, window)
    table.insert(contextGroup.parent.children, window)

    contextGroup.parent:reflow()

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