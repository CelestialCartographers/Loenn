local utils = require("utils")
local stringField = require("ui.forms.fields.string")

local decalTextureField = {}

decalTextureField.fieldType = "decalTexture"

local function displayTransformer(texture)
    return string.match(texture, "^decals/(.*)")
end

local function valueTransformer(texture)
    return "decals/" .. texture
end

function decalTextureField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    options.valueTransformer = valueTransformer
    options.displayTransformer = displayTransformer

    return stringField.getElement(name, value, options)
end

return decalTextureField