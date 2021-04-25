local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

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

local function fieldChanged(formField)
    return function(element, new, old)
        local wasValid = formField:fieldValid()
        local valid = formField.validator(new)

        formField.currentValue = formField.valueTransformer(new)

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

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(displayTransformer(value), fieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })

    field:setPlaceholder(displayTransformer(value))

    local element = uiElements.row({
        label,
        field
    })

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
        label, field
    }

    return setmetatable(formField, stringField._MT)
end

return stringField