local keyboardHelper = require("utils.keyboard")

local specialKeyAliases = {
    plus = "+",
    minus = "-",
}

local modifierKeyFunctions = keyboardHelper.nameToModifierFunction

local hotkeyStruct = {}

-- TODO - Validate that the key constant exists?
-- Exact match means that ctrl + s will only be valid on ctrl + s, and not ctrl + alt + s and so on
function hotkeyStruct.sanitize(activator, exactMatch)
    local activatorType = type(activator)

    if activatorType == "table" then
        return activator
    end

    if not activator then
        return false
    end

    exactMatch = exactMatch == nil or exactMatch

    local parts = string.split(activator, "+")
    local activators = {}

    local usedModifiers = {}

    for i, part <- parts do
        part = part:match("^%s*(.-)%s*$"):lower()

        if specialKeyAliases[part] then
            table.insert(activators, specialKeyAliases[part])

        elseif modifierKeyFunctions[part] then
            local func = modifierKeyFunctions[part]

            table.insert(activators, func)

            usedModifiers[modifierKeyFunctions[part]] = true

        else
            table.insert(activators, part)
        end
    end

    if exactMatch then
        for name, func in pairs(modifierKeyFunctions) do
            if not usedModifiers[func] then
                -- Make sure we don't add any aliases for the function either
                usedModifiers[func] = true

                table.insert(activators, function() return not func() end)
            end
        end
    end

    return activators
end

function hotkeyStruct.hotkeyActive(hotkey)
    if hotkeyStruct.disabled(hotkey) then
        return false
    end

    for i, part in ipairs(hotkey.activator) do
        if type(part) == "function" then
            if not part() then
                return false
            end

        else
            if not love.keyboard.isDown(part) then
                return false
            end
        end
    end

    return true
end

function hotkeyStruct.callbackIfActive(hotkey)
    if hotkey:active() then
        hotkey()
    end
end

function hotkeyStruct.callbackFirstActive(hotkeys)
    for i, hotkey in ipairs(hotkeys) do
        if hotkey:active() then
            hotkey()

            return true, i
        end
    end

    return false, false
end

function hotkeyStruct.disabled(hotkey)
    return not hotkey.activator or not hotkey.enabled
end

local hotkeyMt = {}

hotkeyMt.__index = {}
hotkeyMt.__index.active = hotkeyStruct.hotkeyActive
hotkeyMt.__index.callbackIfActive = hotkeyStruct.callbackIfActive

function hotkeyMt:__call()
    self:callback()
end

function hotkeyStruct.createHotkey(activator, callback)
    local hotkey = {
        _type = "hotkey",
        _rawActivator = activator
    }

    hotkey.callback = callback
    hotkey.activator = hotkeyStruct.sanitize(activator)
    hotkey.enabled = true

    return setmetatable(hotkey, hotkeyMt)
end

return hotkeyStruct