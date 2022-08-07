local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local booleanField = {}

booleanField.fieldType = "boolean"

booleanField._MT = {}
booleanField._MT.__index = {}

function booleanField._MT.__index:setValue(value)
    self.currentValue = value
end

function booleanField._MT.__index:getValue()
    return self.currentValue
end

function booleanField._MT.__index:fieldValid()
    return type(self:getValue()) == "boolean"
end

local function fieldChanged(formField)
    return function(element, new)
        local old = formField.currentValue

        formField.currentValue = new

        if formField.currentValue ~= old then
            formField:notifyFieldChanged()
        end
    end
end

function booleanField.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    local checkbox = uiElements.checkbox(options.displayName or name, value, fieldChanged(formField))
    local element = checkbox

    if options.tooltipText then
        checkbox.interactive = 1
        checkbox.tooltipText = options.tooltipText
    end

    checkbox.centerVertically = true

    formField.checkbox = checkbox
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.sortingPriority = 10
    formField.width = 1
    formField.elements = {
        checkbox
    }

    return setmetatable(formField, booleanField._MT)
end

return booleanField