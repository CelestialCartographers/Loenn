local stringField = require("ui.forms.fields.string")
local utils = require("utils")

local integerField = {}

integerField.fieldType = "integer"

-- Any integers outside of this range are not safe to save
local largestInt = math.floor(2^31 - 1)
local smallestInt = math.floor(-2^31)

function integerField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local minimumValue = math.max(options.minimumValue or smallestInt, smallestInt)
    local maximumValue = math.min(options.maximumValue or largestInt, largestInt)

    options.valueTransformer = tonumber
    options.displayTransformer = tostring
    options.validator = function(v)
        local number = tonumber(v)

        return utils.isInteger(number) and number >= minimumValue and number <= maximumValue
    end

    return stringField.getElement(name, value, options)
end

return integerField