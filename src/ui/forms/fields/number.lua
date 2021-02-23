local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local numberField = {}

numberField.fieldType = "number"

numberField._MT = {}
numberField._MT.__index = {}

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function numberField._MT.__index:setValue(value)
    self.field:setText(tostring(value))
    self.currentValue = value
end

function numberField._MT.__index:getValue()
    return self.currentValue
end

function numberField._MT.__index:fieldValid()
    return type(self:getValue()) == "number"
end

local function fieldChanged(formField)
    return function(element, new, old)
        local wasValid = formField:fieldValid()
        local valid = tonumber(new) ~= nil

        formField.currentValue = tonumber(new)

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

function numberField.getElement(name, value, options)
    local formField = {}

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(tostring(value), fieldChanged(formField)):with({
        minWidth = 160,
        maxWidth = 160
    })

    field:setPlaceholder(tostring(value))

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
    formField.width = 2
    formField.elements = {
        label, field
    }

    return setmetatable(formField, numberField._MT)
end

return numberField