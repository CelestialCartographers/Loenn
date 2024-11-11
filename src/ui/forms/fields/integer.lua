local stringField = require("ui.forms.fields.string")
local utils = require("utils")

local integerField = {}

integerField.fieldType = "integer"

-- Any integers outside of this range are not safe to save
local largestInt = math.floor(2^31 - 1)
local smallestInt = math.floor(-2^31)

local function valueValidator(raw, value, allowEmpty, minimum, maximum)
    if raw == "" then
        return allowEmpty
    end

    local number = tonumber(value)

    return utils.isInteger(number) and number <= maximum and number >= minimum
end

function integerField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local minimumValue = math.max(options.minimumValue or smallestInt, smallestInt)
    local maximumValue = math.min(options.maximumValue or largestInt, largestInt)
    local warningBelowValue = options.warningBelowValue or minimumValue
    local warningAboveValue = options.warningAboveValue or maximumValue
    local allowEmpty = options.allowEmpty or false

    options.valueTransformer = tonumber
    options.displayTransformer = function(v)
        if v == nil or type(v) ~= "number" then
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

return integerField