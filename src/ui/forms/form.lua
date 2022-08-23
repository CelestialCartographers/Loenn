local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local configs = require("configs")

local modHandler = require("mods")
local pluginLoader = require("plugin_loader")

local gridElement = require("ui.widgets.grid")
local widgetUtils = require("ui.widgets.utils")

local forms = {}

forms.registeredFieldTypes = {}

function forms.getFieldElement(name, value, options)
    local fieldType = options and options.fieldType or utils.typeof(value)
    local handler = forms.registeredFieldTypes[fieldType]

    if handler then
        return handler.getElement(name, value, options)

    else
        local unknownHandler = forms.registeredFieldTypes["unknown_type"]

        return unknownHandler.getElement(name, value, options)
    end
end

function forms.getFieldOptions(name, options)
    return options.fields and options.fields[name] or {}
end

function forms.getNameParts(name, options)
    local delimiter = options and options.nestedDataDelimiter

    if delimiter == false then
        return {name}

    elseif delimiter == nil then
        delimiter = "."
    end

    return name:split(delimiter)()
end

local function fieldSortingFunction(a, b)
    -- Sort by sortingPriority, if they match then the elements are alphabetically sorted

    local optionsA = a._options
    local optionsB = b._options

    local weightA = optionsA.sortingPriority or a.sortingPriority or 0
    local weightB = optionsB.sortingPriority or b.sortingPriority or 0

    if weightA ~= weightB then
        return weightA < weightB
    end

    local nameA = optionsA.displayName or a.name
    local nameB = optionsB.displayName or b.name

    return nameA < nameB
end

function forms.getFormFields(data, options)
    local ignored = table.flip(options.ignored or {})
    local ignoreUnordered = options.ignoreUnordered
    local hidden = table.flip(options.hidden or {})
    local hideUnordered = options.hideUnordered
    local fieldOrder = options.fieldOrder or {}

    local elements = {}

    local fieldChangedCallback = function(changedField)
        elements._lastChange = love.timer.getTime()
        elements._formValid = forms.formValid(elements)

        if options.formFieldChanged then
            options.formFieldChanged(elements, changedField)
        end
    end

    for _, name in ipairs(fieldOrder) do
        local nameParts = forms.getNameParts(name, options)
        local value = utils.getPath(data, nameParts)
        local fieldOptions = forms.getFieldOptions(name, options)
        local element = forms.getFieldElement(name, value, fieldOptions)

        ignored[name] = true
        element._hidden = hidden[name]
        element._options = fieldOptions

        table.insert(elements, element)
    end

    if not ignoreUnordered then
        local unorderedElements = {}

        for name, value in pairs(data) do
            if not ignored[name] then
                local fieldOptions = forms.getFieldOptions(name, options)
                local element = forms.getFieldElement(name, value, fieldOptions)

                if hidden[name] ~= nil then
                    element._hidden = hidden[name]

                else
                    element._hidden = hideUnordered
                end

                element._options = fieldOptions

                table.insert(unorderedElements, element)
            end
        end

        table.sort(unorderedElements, fieldSortingFunction)

        for _, element in ipairs(unorderedElements) do
            table.insert(elements, element)
        end
    end

    -- Add extra fields
    for _, element in ipairs(elements) do
        element.notifyFieldChanged = fieldChangedCallback
    end

    -- Initial validation
    elements._formValid = forms.formValid(elements)

    return elements
end

function forms.getFormFieldsGrid(formFields, options)
    local columnCount = options.columns or 4
    local elements = {}
    local column = 1
    local rows = 0

    for _, field in ipairs(formFields) do
        local fieldWidth = field.width or 1

        if not field._hidden then
            if column + fieldWidth - 1 > columnCount then
                -- False gives us a blank grid cell
                for i = column, columnCount do
                    table.insert(elements, false)
                end

                column = 1
                rows += 1
            end

            for _, element in ipairs(field.elements) do
                table.insert(elements, element)

                column += 1
            end
        end
    end

    return gridElement.getGrid(elements, columnCount)
end

function forms.getFormBody(data, options)
    local formFields = forms.getFormFields(data, options)
    local grid = forms.getFormFieldsGrid(formFields, options)

    formFields._options = options

    return grid, formFields
end

function forms.formValid(formFields)
    local invalidFields = {}

    for _, field in ipairs(formFields) do
        if not field:fieldValid() then
            table.insert(invalidFields, field.name)
        end
    end

    return #invalidFields == 0, invalidFields
end

function forms.getFormData(formFields)
    local data = {}

    for _, field in ipairs(formFields) do
        if field.name then
            local nameParts = forms.getNameParts(field.name, formFields._options)

            utils.setPath(data, nameParts, field:getValue(), true)
        end
    end

    return data
end

function forms.setFormData(formFields, data, alwaysUpdate)
    for _, field in ipairs(formFields) do
        if field.name then
            local nameParts = forms.getNameParts(field.name, formFields._options)
            local newValue = utils.getPath(data, nameParts)

            if alwaysUpdate ~= false or newValue then
                field:setValue(newValue)
            end
        end
    end
end

function forms.buttonUpdateHandler(formFields, button)
    return function(orig, self, dt)
        local formMustBeValid = button.formMustBeValid
        local formValid = formFields._formValid or false
        local enabled = utils.callIfFunction(button.enabled, formFields, button)

        if enabled ~= nil or formMustBeValid then
            local newEnabled = true

            if enabled ~= nil then
                newEnabled = enabled
            end

            if formMustBeValid then
                newEnabled = newEnabled and formValid
            end

            self:setEnabled(newEnabled)
        end

        orig(self, dt)
    end
end

function forms.packFormButtonCallback(formFields, func)
    func = func or function() end

    return function(self, x, y, button)
        return func(formFields, self)
    end
end

function forms.getFormButtonRow(buttons, formFields, options)
    local buttonElements = {}

    for i, button in ipairs(buttons) do
        local callback = forms.packFormButtonCallback(formFields, button.callback)
        local buttonElement = uiElements.button(button.text, callback)

        buttonElement:hook({
            update = forms.buttonUpdateHandler(formFields, button)
        })

        if button.enabled ~= nil then
            buttonElement.enabled = utils.callIfFunction(button.enable, formField, button)
        end

        buttonElements[i] = buttonElement
    end

    local buttonRow = uiElements.row(buttonElements):with({
        style = {
            padding = 8
        }
    })

    return buttonRow
end

function forms.getForm(buttons, data, options)
    buttons = buttons or {}
    data = data or {}
    options = options or {}

    local body, formFields = forms.getFormBody(data, options)
    local buttonRow = forms.getFormButtonRow(buttons, formFields, options)
    local scrollableBody = uiElements.scrollbox(body)

    if options.scrollable ~= false then
        buttonRow:with(uiUtils.bottombound):with(uiUtils.fillWidth)
        scrollableBody:hook({
            calcWidth = function(orig, element)
                return element.inner.width
            end,
        }):with(uiUtils.fillHeight(true))
    end

    return uiElements.column({scrollableBody, buttonRow}):with(uiUtils.fillHeight(true))
end

function forms.prepareScrollableWindow(window, maxHeight)
    window:with(widgetUtils.fillHeightIfNeeded(maxHeight))
end

function forms.loadFieldType(filename, registerAt, verbose)
    -- Use verbose flag or default to logPluginLoading from config
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading
    registerAt = registerAt or forms.registeredFieldTypes

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local fieldType = handler.fieldType or filenameNoExt

    registerAt[fieldType] = handler
end

function forms.loadInternalFieldTypes(path)
    path = path or "ui/forms/fields"

    pluginLoader.loadPlugins(path, nil, forms.loadFieldType, false)
end

function forms.loadExternalFieldTypes()
    local filenames = modHandler.findPlugins("ui/forms/fields")

    pluginLoader.loadPlugins(filenames, nil, forms.loadFieldType, false)
end

function forms.unloadFieldTypes()
    forms.registeredFieldTypes = {}
end

return forms