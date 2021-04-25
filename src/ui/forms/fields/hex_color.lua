local stringField = require("ui.forms.fields.string")
local utils = require("utils")

local colorField = {}

colorField.fieldType = "hex_color"

function colorField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    options.validator = function(v)
        local parsed, r, g, b = utils.parseHexColor(v)

        return parsed
    end

    return stringField.getElement(name, value, options)
end

return colorField