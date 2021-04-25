local stringField = require("ui.forms.fields.string")
local utils = require("utils")

local integerField = {}

integerField.fieldType = "integer"

function integerField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    options.valueTransformer = tonumber
    options.displayTransformer = tostring
    options.validator = utils.isInteger

    return stringField.getElement(name, value, options)
end

return integerField