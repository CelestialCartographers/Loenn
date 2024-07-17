local utils = require("utils")
local stringField = require("ui.forms.fields.string")

local numberField = {}

numberField.fieldType = "number"

local function valueValidator(raw, value, allowEmpty, minimum, maximum)
    if raw == "" then
        return allowEmpty
    end

    local number = tonumber(value)

    return number ~= nil and number <= maximum and number >= minimum
end

function numberField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local minimumValue = options.minimumValue or -math.huge
    local maximumValue = options.maximumValue or math.huge
    local warningBelowValue = options.warningBelowValue or minimumValue
    local warningAboveValue = options.warningAboveValue or maximumValue
    local allowEmpty = options.allowEmpty or false

    options.valueTransformer = tonumber
    options.displayTransformer = function(v)
        if allowEmpty and value == nil then
            return ""
        end

        return tostring(v)
    end
    options.warningValidator = function(v, raw)
        return valueValidator(raw, v, allowEmpty, warningBelowValue, warningAboveValue)
    end
    options.validator = function(v, raw)
        return valueValidator(raw, v, allowEmpty, minimumValue, maximumValue)
    end

    return stringField.getElement(name, value, options)
end

return numberField