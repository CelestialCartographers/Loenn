local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local stringField = {}

stringField.fieldType = "string"

stringField._MT = {}
stringField._MT.__index = {}

function stringField._MT.__index:setValue(value)
    self.field:setText(value)
    self.currentValue = value
end

function stringField._MT.__index:getValue()
    return self.currentValue
end

function stringField._MT.__index:fieldValid()
    return type(self:getValue()) == "string"
end

local function fieldChanged(formField)
    return function(element, new, old)
        formField.currentValue = new
    end
end

function stringField.getElement(name, value, options)
    local formField = {}

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(value, fieldChanged(formField)):with({
        minWidth = 160,
        maxWidth = 160
    })

    field:setPlaceholder(value)

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

    return setmetatable(formField, stringField._MT)
end

return stringField