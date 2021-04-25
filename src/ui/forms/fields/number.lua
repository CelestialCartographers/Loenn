local stringField = require("ui.forms.fields.string")

local numberField = {}

numberField.fieldType = "number"

function numberField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    options.valueTransformer = tonumber
    options.displayTransformer = tostring
    options.validator = function(v)
        return tonumber(v) ~= nil
    end

    return stringField.getElement(name, value, options)
end

return numberField