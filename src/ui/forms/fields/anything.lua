local stringField = require("ui.forms.fields.string")
local utils = require("utils")

local anythingField = {}

anythingField.fieldType = "anything"

function anythingField.getElement(name, value, options)
    -- Allows any value
    -- Works best with non editable dropdowns
    -- Add extra options and pass it onto string field

    options.displayTransformer = tostring
    options.validator = function(v)
        return true
    end

    return stringField.getElement(name, value, options)
end

return anythingField