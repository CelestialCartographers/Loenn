-- Fallback for missing values

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local nilField = {}

nilField.fieldType = "nil"

nilField._MT = {}
nilField._MT.__index = {}

function nilField._MT.__index:setValue(value)
    self.currentValue = value
end

function nilField._MT.__index:getValue()
    return self.currentValue
end

function nilField._MT.__index:fieldValid()
    return true
end

function nilField.getElement(name, value, options)
    local formField = {}

    formField.width = 0
    formField.elements = {}

    return setmetatable(formField, nilField._MT)
end

return nilField