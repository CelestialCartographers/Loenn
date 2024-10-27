local parallax = require("parallax")

local apply = {}

local defaultData = {
    _name = ""
}

local fieldOrder = table.shallowcopy(parallax.fieldOrder())
local fieldInformation = table.shallowcopy(parallax.fieldInformation())

table.insert(fieldOrder, 1, "_name")

function apply.defaultData(style)
    return defaultData
end

function apply.fieldOrder(style)
    return fieldOrder
end

function apply.fieldInformation(style)
    return fieldInformation
end

function apply.canForeground(style)
    return true
end

function apply.canBackground(style)
    return true
end

function apply.languageData(language, style)
    return language.style.apply
end

function apply.displayName(language, style, index)
    if style._name and style._name ~= "" then
        return style._name
    end

    local groupTemplate = tostring(language.style.apply.groupName)

    return string.format(groupTemplate, index)
end

return apply