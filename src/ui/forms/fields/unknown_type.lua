local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")

local unknownField = {}

unknownField.fieldType = "unknown_type"

unknownField._MT = {}
unknownField._MT.__index = {}

function unknownField._MT.__index:setValue(value)
    self.currentValue = value
end

function unknownField._MT.__index:getValue()
    return self.currentValue
end

function unknownField._MT.__index:fieldValid()
    return true
end

function unknownField.getElement(name, value, options)
    local formField = {}

    local fieldType = options and options.fieldType or utils.typeof(value)
    local label = uiElements.label(string.format("Unknown field for type '%s' in field '%s'", fieldType, name))

    label.centerVertically = true

    formField.initialValue = value
    formField.currentValue = value
    formField.width = 1
    formField.elements = {
        label
    }

    return setmetatable(formField, unknownField._MT)
end

return unknownField