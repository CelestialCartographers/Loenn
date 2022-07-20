local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local fieldDropdown = require("ui.widgets.field_dropdown")

local stringField = {}

stringField.fieldType = "string"

stringField._MT = {}
stringField._MT.__index = {}

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function stringField._MT.__index:setValue(value)
    self.field:setText(self.displayTransformer(value))
    self.currentValue = self.valueTransformer(value)
end

function stringField._MT.__index:getValue()
    return self.currentValue
end

function stringField._MT.__index:fieldValid()
    return self.validator(self:getValue())
end

local function updateFieldStyle(formField, wasValid, valid)
    if wasValid ~= valid then
        if valid then
            -- Reset to default
            formField.field.style = nil

        else
            formField.field.style = invalidStyle
        end

        formField.field:repaint()
    end
end

local function fieldChanged(formField)
    return function(element, new, old)
        local wasValid = formField:fieldValid()
        local valid = formField.validator(new)

        formField.currentValue = formField.valueTransformer(new)

        updateFieldStyle(formField, wasValid, valid)
        formField:notifyFieldChanged()
    end
end

local function dropdownChanged(formField, optionsFlattened)
    return function(element, new)
        local value
        local old = formField.currentValue

        for _, option in ipairs(optionsFlattened) do
            if option[1] == new then
                value = option[2]
            end
        end

        if value ~= old then
            local wasValid = formField:fieldValid()
            local valid = formField.validator(value)

            formField.currentValue = value

            updateFieldStyle(formField, wasValid, valid)
            formField:notifyFieldChanged()
        end
    end
end

local function prepareDropdownOptions(value, options, displayTransformer, insertMissing)
    local flattenedOptions = {}
    local seenValueName

    -- Assume this is a unordered table, manually flatten
    if #options == 0 then
        for k, v in pairs(options) do
            table.insert(flattenedOptions, {k, v})

            if v == value then
                seenValueName = k
            end
        end

        -- Sort by name
        flattenedOptions = table.sortby(flattenedOptions, (t -> t[1]))()

    else
        -- Check if already flattened or only values
        if type(options[1]) == "table" then
            for i, option in ipairs(options) do
                flattenedOptions[i] = option

                if option[2] == value then
                    seenValueName = option[1]
                end
            end

        else
            for i, v in ipairs(options) do
                local name = displayTransformer(v)

                flattenedOptions[i] = {name, v}

                if v == value then
                    seenValueName = name
                end
            end
        end
    end

    if insertMissing ~= false and not seenValueName then
        seenValueName = displayTransformer(value)

        table.insert(flattenedOptions, {seenValueName, value})
    end

    return flattenedOptions, seenValueName
end

function stringField.getElement(name, value, options)
    local formField = {}

    local validator = options.validator or function(v)
        return type(v) == "string"
    end

    local valueTransformer = options.valueTransformer or function(v)
        return v
    end

    local displayTransformer = options.displayTransformer or function(v)
        return v
    end

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    local dropdownOptions = options.options
    local editable = options.editable
    local dropdown

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(displayTransformer(value), fieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local element = field

    if editable == false then
        field:setEnabled(false)
    end

    field:setPlaceholder(displayTransformer(value))

    if dropdownOptions then
        local optionsFlattened, currentText = prepareDropdownOptions(value, dropdownOptions, displayTransformer)
        local optionStrings = {}
        local selectedIndex = -1

        for i, option in ipairs(optionsFlattened) do
            optionStrings[i] = option[1]

            if option[1] == currentText then
                selectedIndex = i
            end
        end

        dropdown = uiElements.dropdown(optionStrings, dropdownChanged(formField, optionsFlattened)):with({
            minWidth = minWidth,
            maxWidth = maxWidth
        })

        dropdown:setSelected(value, currentText)
        dropdown.selected = dropdown:getItem(selectedIndex)

        if editable == false then
            element = dropdown

        else
            fieldDropdown.addDropdown(field, dropdown, currentText)
        end
    end

    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.field = field
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.validator = validator
    formField.valueTransformer = valueTransformer
    formField.displayTransformer = displayTransformer
    formField.width = 2
    formField.elements = {
        label, element
    }

    return setmetatable(formField, stringField._MT)
end

return stringField