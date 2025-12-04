local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local configs = require("configs")

local modHandler = require("mods")
local pluginLoader = require("plugin_loader")

local gridElement = require("ui.widgets.grid")
local separatorElement = require("ui.widgets.separator")
local widgetUtils = require("ui.widgets.utils")

local forms = {}

forms.changeMark = "• "

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

    for _, name in ipairs(fieldOrder) do
        local nameParts = forms.getNameParts(name, options)
        local fieldOptions = forms.getFieldOptions(name, options)
        local defaultValue = fieldOptions.default
        local value = utils.getPath(data, nameParts, defaultValue)
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

    return elements
end

-- TODO - Force new row somehow support thanks
function forms.getFormFieldsGrid(formFields, options)
    local columnCount = options.columns or 4
    local elements = {}
    local column = 1
    local rows = 0

    for _, field in ipairs(formFields) do
        local fieldWidth = field.width or 1

        if field.breakRow then
            for i = column, columnCount do
                table.insert(elements, false)
            end

            column = 1
            rows += 1
        end

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

function forms.getFormBodyGroups(data, options)
    local groups = options.groups
    local allFormFields = forms.getFormFields(data, options)
    local grids = {}
    local bodyColumn = uiElements.column({}):with({
        style = {
            padding = 0,
            spacing = 0
        }
    })

    for i, groupOptions in ipairs(groups) do
        local newGroupOptions = {}

        if newGroupOptions.inheritOptions ~= false then
            newGroupOptions = utils.deepcopy(options)

            -- Do not copy groups
            newGroupOptions.groups = nil
        end

        for k, v in pairs(groupOptions) do
            newGroupOptions[k] = v
        end

        local formFields = forms.getFormFields(data, newGroupOptions)
        local grid = forms.getFormFieldsGrid(formFields, options)

        for _, field in ipairs(formFields) do
            table.insert(allFormFields, field)
        end

        if groupOptions.title then
            local separator = uiElements.lineSeparator(groupOptions.title, 16, true)

            -- If this is not the first title separator, add some space above
            if i > 1 then
                separator:addBottomPadding()
            end

            bodyColumn:addChild(separator)
        end

        bodyColumn:addChild(grid)
        table.insert(grids, grid)

        -- Move padding up a notch, makes our line separators match the content properly
        bodyColumn.style.padding = grid.style.padding
        grid.style.padding = 0
    end

    gridElement.alignColumns(grids)

    allFormFields._options = options

    return bodyColumn, allFormFields
end

local fieldChangedCallback = function(formFields, options)
    return function(changedField)
        formFields._lastChange = love.timer.getTime()
        formFields._formValid = forms.formValid(formFields)
        formFields._hasChanges = forms.formHasChanges(formFields)

        if options.formFieldChanged then
            options.formFieldChanged(formFields, changedField)
        end

        if formFields.formFieldChanged then
            formFields.formFieldChanged(changedField)
        end
    end
end

function forms.addTabFocusing(formFields, buttonElements, options)
    if options.addTabFocus == false then
        return
    end

    local interactiveElements = {}

    for _, field in ipairs(formFields) do
        for _, element in ipairs(field.elements) do
            local elementType = utils.typeof(element)

            if element.interactive ~= 0 and elementType ~= "label"  then
                table.insert(interactiveElements, element)
            end
        end
    end

    for _, button in ipairs(buttonElements) do
        table.insert(interactiveElements, button)
    end

    for i, element in ipairs(interactiveElements) do
        widgetUtils.addTabCycleHook(element, interactiveElements[i + 1], interactiveElements[i - 1])
    end

    return interactiveElements
end

function forms.prepareFormFields(formFields, options)
    -- Add extra fields for validation
    for _, field in ipairs(formFields) do
        field.notifyFieldChanged = fieldChangedCallback(formFields, options)
        field.metadata = options.fieldMetadata
    end

    -- Initial validation
    formFields._formValid = forms.formValid(formFields)
    formFields._initialData = forms.getFormData(formFields)
end

function forms.getFormBody(data, options)
    local groups = options.groups
    local grid, formFields

    if groups then
        grid, formFields = forms.getFormBodyGroups(data, options)

    else
        formFields = forms.getFormFields(data, options)
        grid = forms.getFormFieldsGrid(formFields, options)

        formFields._options = options
    end

    forms.prepareFormFields(formFields, options)

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

function forms.formDataSaved(formFields)
    local data = forms.getFormData(formFields)

    formFields._initialData = data
    formFields._hasChanges = false

    forms.updateWindowChangedTitle(formFields)
end

function forms.formHasChanges(formFields)
    local data = forms.getFormData(formFields)
    local initialData = formFields._initialData

    return not utils.equals(data, initialData)
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

            if self.enabled ~= newEnabled then
                self.enabled = newEnabled
            end
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

        buttonElement.__formButtonInfo = button
        buttonElement:hook({
            update = forms.buttonUpdateHandler(formFields, button)
        }):with({
            formSetEnabled = function(self, value)
                -- Make sure the button and form both get the new enabled value
                self.enabled = value
                self.__formButtonInfo.enabled = value
            end
        })

        if button.enabled ~= nil then
            buttonElement.enabled = utils.callIfFunction(button.enabled, formFields, button)
        end

        buttonElements[i] = buttonElement
    end

    local buttonRow = uiElements.row(buttonElements):with({
        style = {
            padding = 8
        }
    })

    return buttonRow, buttonElements
end

function forms.getForm(buttons, data, options)
    buttons = buttons or {}
    data = data or {}
    options = options or {}

    local body, formFields = forms.getFormBody(data, options)

    local buttonRow, buttonElements = forms.getFormButtonRow(buttons, formFields, options)
    local scrollableBody = uiElements.scrollbox(body)

    local interactiveElements = forms.addTabFocusing(formFields, buttonElements, options)

    if options.scrollable ~= false then
        buttonRow:with(uiUtils.bottombound):with(uiUtils.fillWidth)
        scrollableBody:hook({
            calcWidth = function(orig, element)
                return element.inner.width
            end,
        }):with(uiUtils.fillHeight(true))
    end

    local form = uiElements.column({scrollableBody, buttonRow}):with(uiUtils.fillHeight(true))

    form._formFields = form
    form._interactiveElements = interactiveElements

    return form, formFields
end

function forms.prepareScrollableWindow(window, maxHeight)
    window:with(widgetUtils.fillHeightIfNeeded(minHeight, maxHeight))
end

function forms.updateWindowChangedTitle(formFields)
    local window = formFields._window
    local baseTitle = formFields._baseTitle

    if not window or not baseTitle then
        return
    end

    local titlePrefix = formFields._hasChanges and forms.changeMark or ""
    local newTitle = titlePrefix .. baseTitle

    widgetUtils.setWindowTitle(window, newTitle)
end

function forms.addTitleChangeHandler(window, baseTitle, formFields)
    formFields._window = window
    formFields._baseTitle = baseTitle

    local function formFieldChanged()
        forms.updateWindowChangedTitle(formFields)
    end

    -- Set directly if we can, otherwise add a wrapper
    if formFields.formFieldChanged then
        local originalCallback = formFields.formFieldChanged

        formFields.formFieldChanged = function()
            originalCallback()
            formFieldChanged()
        end

    else
        formFields.formFieldChanged = formFieldChanged
    end
end

function forms.focusFirstElement(form)
    ui.runLate(function()
        widgetUtils.focusElement(form._interactiveElements[1])
    end)
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