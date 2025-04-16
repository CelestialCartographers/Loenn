local parallax = require("parallax")
local effects = require("effects")
local utils = require("utils")

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

local function canForegroundBackgroundCommon(style, fg)
    local funcKey = fg and "canForeground" or "canBackground"

    for _, child in ipairs(style.children) do
        local handler = utils.typeof(child) == "parallax" and parallax or effects

        if not handler[funcKey](child) then
            return false
        end
    end

    return true
end

-- Check that all children can foreground
function apply.canForeground(style)
    return canForegroundBackgroundCommon(style, true)
end

-- Check that all children can background
function apply.canBackground(style)
    return canForegroundBackgroundCommon(style, false)
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