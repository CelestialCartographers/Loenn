 -- Fallback for missing values

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local spaceField = {}

spaceField.fieldType = "spacer"

spaceField._MT = {}
spaceField._MT.__index = {}

function spaceField._MT.__index:setValue(value)
    self.currentValue = value
end

function spaceField._MT.__index:getValue()
    return self.currentValue
end

function spaceField._MT.__index:fieldValid()
    return true
end

function spaceField.getElement(name, value, options)
    local formField = {}

    formField.name = name
    formField.width = 0
    formField.breakRow = true
    formField.elements = {}

    return setmetatable(formField, spaceField._MT)
end

return spaceField