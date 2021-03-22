-- Dummy field type for now
-- Just hides the nodes value but allows them to be passed around in forms

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local nodesField = {}

nodesField.fieldType = "nodes"

nodesField._MT = {}
nodesField._MT.__index = {}

function nodesField._MT.__index:setValue(value)
    self.currentValue = value
end

function nodesField._MT.__index:getValue()
    return self.currentValue
end

function nodesField._MT.__index:fieldValid()
    return true
end

function nodesField.getElement(name, value, options)
    local formField = {}

    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.width = 0
    formField.elements = {}

    return setmetatable(formField, nodesField._MT)
end

return nodesField