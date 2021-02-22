local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
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
    local language = languageRegistry.getLanguage()
    local formField = {}

    local labelText = tostring(language.forms.fieldTypes.unknown_type.label)
    local fieldType = options and options.fieldType or utils.typeof(value)
    local label = uiElements.label(string.format(labelText, fieldType, name))

    label.centerVertically = true

    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.width = 1
    formField.elements = {
        label
    }

    return setmetatable(formField, unknownField._MT)
end

return unknownField