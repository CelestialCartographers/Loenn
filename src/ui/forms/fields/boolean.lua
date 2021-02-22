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

local function dropdownChanged(self)
    return function(element, new)
        self.currentValue = new == "True"
    end
end

-- TODO - Change to a proper checkbox when possible
function booleanField.getElement(name, value, options)
    local formField = {}

    local label = uiElements.label(options.displayName or name)
    local dropdown = uiElements.dropdown({"True", "False"}, dropdownChanged(formField)):with({
        minWidth = 160,
        maxWidth = 160
    })

    local element = uiElements.row({
        label,
        dropdown
    })

    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.dropdown = dropdown
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.width = 2
    formField.elements = {
        label, dropdown
    }

    return setmetatable(formField, booleanField._MT)
end

return booleanField