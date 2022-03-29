local utils = require("utils")

local effects = {}

local defaultFieldOrder = {}

-- TODO - Default data

function effects.ignoredFields(style)
    -- TODO - Get from plugin

    return {"_name"}
end

function effects.fieldOrder(style)
    -- TODO - Get from plugin

    return defaultFieldOrder
end

function effects.fieldInformation(style)
    -- TODO - Get from plugin

    return {}
end

function effects.languageData(language, style)
    local styleName = style._name

    return language.style.effects[styleName], language.style.effects.default
end

return effects