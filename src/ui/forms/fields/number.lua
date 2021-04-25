local stringField = require("ui.forms.fields.string")

local numberField = {}

numberField.fieldType = "number"

function numberField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local minimumValue = options.minimumValue or -math.huge
    local maximumValue = options.maximumValue or math.huge

    options.valueTransformer = tonumber
    options.displayTransformer = tostring
    options.validator = function(v)
        local number = tonumber(v)

        return number ~= nil and number >= minimumValue and number <= maximumValue
    end

    return stringField.getElement(name, value, options)
end

return numberField