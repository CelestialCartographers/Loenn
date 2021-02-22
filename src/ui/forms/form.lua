local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local configs = require("configs")

local modHandler = require("mods")
local pluginLoader = require("plugin_loader")

local forms = {}

forms.registereFieldTypes = {}

function forms.getFieldElement(name, value, options)
    local fieldType = options and options.fieldType or utils.typeof(value)
    local handler = forms.registereFieldTypes[fieldType]

    if handler then
        return handler.getElement(name, value, options)

    else
        local unknownHandler = forms.registereFieldTypes["unknown_type"]

        return unknownHandler.getElement(name, value, options)
    end
end

-- TODO - Options
-- Dropdowns, editable, etc
function forms.getFormFields(data, options)
    local ignored = table.flip(options.ignored or {})
    local ignoreUnordered = options.ignoreUnordered
    local fieldOrder = options.fieldOrder or {}

    local elements = {}

    for _, name in ipairs(fieldOrder) do
        local fieldOptions = options.fields and options.fields[name] or {}
        local element = forms.getFieldElement(name, data[name], fieldOptions)

        ignored[name] = true

        table.insert(elements, element)
    end

    if not ignoreUnordered then
        for name, value in pairs(data) do
            if not ignored[name] then
                local fieldOptions = options.fields and options.fields[name] or {}
                local element = forms.getFieldElement(name, value, fieldOptions)

                table.insert(elements, element)
            end
        end
    end

    return elements
end

function forms.getFormBody(data, options)
    -- Split form field elements into columns
    local formFields = forms.getFormFields(data, options)
    local columnCount = options.columns or 4
    local columnElements = {}
    local columns = {}

    for i = 1, columnCount do
        columnElements[i] = {}
    end

    local column = 1
    local rows = 0

    for _, field in ipairs(formFields) do
        local fieldWidth = field.width or 1

        if column + fieldWidth - 1 > columnCount then
            column = 1
            rows += 1
        end

        for _, element in ipairs(field.elements) do
            local targetColumn = columnElements[column]

            table.insert(targetColumn, element)

            column += 1
        end
    end

    for i = 1, columnCount do
        columns[i] = uiElements.group(columnElements[i]):with({
            style = {
                spacing = 8
            }
        })
    end

    local row = uiElements.row(columns):with({
        style = {
            padding = 8
        }
    })

    ui.runLate(function()
        -- Adjust element Y positions to become more "grid like"
        local offsetY = 0

        for y = 1, rows + 1 do
            local rowHeight = 0

            for x = 1, columnCount do
                local element = columnElements[x][y]

                if element then
                    rowHeight = math.max(rowHeight, element.height)
                end
            end

            for x = 1, columnCount do
                local element = columnElements[x][y]

                if element then
                    local centerVertically = rawget(element, "centerVertically")

                    if centerVertically then
                        element.y = offsetY
                        element.y += (rowHeight - element.height) / 2

                    else
                        element.y = offsetY
                    end
                end
            end

            offsetY += rowHeight + 8
        end

        ui:reflow()
    end)

    return row, formFields
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
        data[field.name] = field:getValue()
    end

    return data
end

function forms.formMustBeValidUpdate(formFields)
    return function(orig, self, dt)
        orig(self, dt)

        self:setEnabled(forms.formValid(formFields))
    end
end

function forms.packFormCallback(formFields, func)
    func = func or function() end

    return function(self, x, y, button)
        return func(formFields, self)
    end
end

-- TODO - Make body scrollable
function forms.getForm(buttons, data, options)
    buttons = buttons or {}
    data = data or {}
    options = options or {}

    local body, formFields = forms.getFormBody(data, options)
    local scrollableBody = uiElements.scrollbox(body)

    local buttonElements = {}

    for i, button in ipairs(buttons) do
        local callback = forms.packFormCallback(formFields, button.callback)
        local formMustBeValid = button.formMustBeValid
        local buttonElement = uiElements.button(button.text, callback)

        if formMustBeValid then
            buttonElement:hook({
                update = forms.formMustBeValidUpdate(formFields)
            })
        end

        buttonElements[i] = buttonElement
    end

    local buttonRow = uiElements.row(buttonElements):with({
        style = {
            padding = 8
        }
    })

    return uiElements.column({body, buttonRow})
end

function forms.loadFieldType(filename, registerAt, verbose)
    -- Use verbose flag or default to logPluginLoading from config
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading
    registerAt = registerAt or forms.registereFieldTypes

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
    forms.registereFieldTypes = {}
end

return forms