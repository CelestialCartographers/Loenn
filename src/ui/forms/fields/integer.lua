local stringField = require("ui.forms.fields.string")
local utils = require("utils")

local integerField = {}

integerField.fieldType = "integer"

function integerField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local minimumValue = options.minimumValue or -math.huge
    local maximumValue = options.maximumValue or math.huge

    options.valueTransformer = tonumber
    options.displayTransformer = tostring
    options.validator = function(v)
        local number = tonumber(v)

        return utils.isInteger(number) and number >= minimumValue and number <= maximumValue
    end

    return stringField.getElement(name, value, options)
end

return integerField