local utils = require("utils")
local stringField = require("ui.forms.fields.string")

local numberField = {}

numberField.fieldType = "number"

function numberField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local minimumValue = options.minimumValue or -math.huge
    local maximumValue = options.maximumValue or math.huge
    local allowEmpty = options.allowEmpty or false

    options.valueTransformer = tonumber
    options.displayTransformer = utils.prettifyFloat
    options.validator = function(v, raw)
        if raw == "" then
            return allowEmpty
        end

        local number = tonumber(v)

        return number ~= nil and number >= minimumValue and number <= maximumValue
    end

    return stringField.getElement(name, value, options)
end

return numberField