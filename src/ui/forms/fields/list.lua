local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local stringField = require("ui.forms.fields.string")
local utils = require("utils")
local iconUtils = require("ui.utils.icons")
local contextMenu = require("ui.context_menu")
local form = require("ui.forms.form")
local languageRegistry = require("language_registry")

local listField = {}

listField.fieldType = "list"

local function getValueParts(value, options)
    local separator = options.valueSeparator
    local parts = string.split(value, separator)()

    -- Special case for empty string and empty default
    -- Otherwise we will never be able to add when the field is empty
    if value == "" and options.valueDefault == "" then
        table.insert(parts, "")
    end

    return parts
end

local function joinValueParts(parts, options)
    local joined = table.concat(parts, options.valueSeparator)

    return joined
end

local function updateContextWindow(formField, options)
    local content = listField.buildContextMenu(formField, options)
    local contextWindow = formField.contextWindow

    if contextWindow and contextWindow.parent then
        contextWindow.children[1]:removeSelf()
        contextWindow:addChild(content)

        -- Make sure the element is considered hovered and focused
        -- Otherwise the context menu will dispose of our injected content
        ui.hovering = content
        ui.focusing = content
    end
end

local function valueDeleteRowHandler(formField, index)
    return function()
        local value = formField:getValue()
        local options = formField.options
        local field = formField.field
        local parts = getValueParts(value, formField.options)

        table.remove(parts, index)

        local joined = joinValueParts(parts, options)

        field:setText(joined)
        updateContextWindow(formField, options)
    end
end

local function valueAddRowHandler(formField)
    return function()
        local value = formField:getValue()
        local options = formField.options
        local field = formField.field
        local parts = getValueParts(value, formField.options)

        table.insert(parts, options.valueDefault or "")

        local joined = joinValueParts(parts, options)

        field:setText(joined)
        updateContextWindow(formField, options)
    end
end

local function getSubFormElements(formField, value, options)
    local language = languageRegistry.getLanguage()
    local elements = {}
    local parts = getValueParts(value, options)

    local baseFormElement = form.getFieldElement("base", options.valueDefault or "", options.elementOptions)
    local valueTransformer = baseFormElement.valueTransformer or tostring

    for i, part in ipairs(parts) do
        local formElement = form.getFieldElement(tostring(i), valueTransformer(part) or part, options.elementOptions)

        -- Remove label if based on string field
        if formElement.elements[1] == formElement.label then
            formElement.width = 1

            table.remove(formElement.elements, 1)
        end

        -- Fake remove button as a form field
        local removeButton = uiElements.button(
            tostring(language.forms.fieldTypes.list.removeButton),
            valueDeleteRowHandler(formField, i)
        )
        local fakeElement = {
            elements = {
                removeButton
            },
            fieldValid = function()
                return true
            end
        }

        table.insert(elements, formElement)
        table.insert(elements, fakeElement)
    end

    return elements
end

local function updateTextfield(formField, formData, options)
    local data = {}

    for k, v in pairs(formData) do
        data[tonumber(k)] = v
    end

    local joined = joinValueParts(data, options)

    formField.field:setText(joined)
end

local function getFormDataStrings(fields)
    local data = {}

    for _, field in ipairs(fields) do
        local i = #data + 1

        if field.getCurrentText then
            data[i] = field:getCurrentText()

        elseif field.getValue then
            data[i] = field:getValue()
        end
    end

    return data
end

function listField.updateSubElements(formField, options)
    if not formField then
        return {}
    end

    local value = formField:getValue()
    local previousValue = formField._previousValue
    local formElements = formField._subElements

    if value ~= previousValue then
        formElements = getSubFormElements(formField, value, options)
    end

    formField._subElements = formElements
    formField._previousValue = value

    return formElements
end

function listField.buildContextMenu(formField, options)
    local language = languageRegistry.getLanguage()
    local formElements = formField._subElements
    local columnElements = {}

    if #formElements > 0 then
        local columnCount = (formElements[1].width or 0) + 1
        local formOptions = {
            columns = columnCount,
            formFieldChanged = function(fields)
                -- Get value raw instead, we need the string, not the "validated" data
                local data = getFormDataStrings(fields)

                formField.subFormValid = form.formValid(fields)
                updateTextfield(formField, data, options)
            end,
        }

        form.prepareFormFields(formElements, formOptions)

        local formGrid = form.getFormFieldsGrid(formElements, formOptions)

        table.insert(columnElements, formGrid)
    end

    local addButton = uiElements.button(
        tostring(language.forms.fieldTypes.list.addButton),
        valueAddRowHandler(formField)
    )

    if #formElements > 0 then
        addButton:with(uiUtils.fillWidth(false))
    end

    table.insert(columnElements, addButton)

    local column = uiElements.column(columnElements)

    return column
end

local function addContextSpawner(formField, options)
    local field = formField.field
    local contextMenuOptions = options.contextMenuOptions or {
        mode = "focused"
    }

    if field.height == -1 then
        field:layout()
    end

    local iconMaxSize = field.height - field.style.padding
    local parentHeight = field.height
    local menuIcon, iconSize = iconUtils.getIcon("list", iconMaxSize)

    if menuIcon then
        local centerOffset = math.floor((parentHeight - iconSize) / 2)
        local folderImage = uiElements.image(menuIcon):with(uiUtils.rightbound(0)):with(uiUtils.at(0, centerOffset))

        folderImage.interactive = 1
        folderImage:hook({
            onClick = function(orig, self)
                orig(self)

                local contextWindow = contextMenu.showContextMenu(listField.buildContextMenu(formField, options), contextMenuOptions)

                formField.contextWindow = contextWindow
            end
        })

        field:addChild(folderImage)
    end
end

function listField.getElement(name, value, options)
    -- Add extra options and pass it onto string field
    options = table.shallowcopy(options or {})

    options.elementOptions = options.elementOptions or {}
    options.valueSeparator = options.valueSeparator or ","
    options.minimumElements = options.minimumElements or 0
    options.maximumElements = options.maximumElements or math.huge

    if not options.elementOptions.fieldType then
        options.elementOptions.fieldType = options.elementOptions.fieldType or "string"
    end

    local formField

    options.validator = function(v)
        if not formField then
            return true
        end

        local subElements = listField.updateSubElements(formField, options)

        -- Do not trust the length of sub elements, might contain delete buttons
        local value = formField:getValue()
        local parts = string.split(value, options.valueSeparator)()

        if #parts < options.minimumElements or #parts > options.maximumElements then
            return false
        end

        return form.formValid(subElements)
    end

    formField = stringField.getElement(name, value, options)

    formField.options = options

    listField.updateSubElements(formField, options)
    addContextSpawner(formField, options)

    return formField
end

return listField