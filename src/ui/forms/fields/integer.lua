local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")

local integerField = {}

integerField.fieldType = "integer"

integerField._MT = {}
integerField._MT.__index = {}

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function integerField._MT.__index:setValue(value)
    self.field:setText(tostring(value))
    self.currentValue = value
end

function integerField._MT.__index:getValue()
    return self.currentValue
end

function integerField._MT.__index:fieldValid()
    local value = self:getValue()

    return utils.isInteger(value)
end

local function fieldChanged(formField)
    return function(element, new, old)
        local newValue = tonumber(new)
        local wasValid = formField:fieldValid()
        local valid = utils.isInteger(newValue)

        formField.currentValue = newValue

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

function integerField.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(tostring(value), fieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
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

    return setmetatable(formField, integerField._MT)
end

return integerField