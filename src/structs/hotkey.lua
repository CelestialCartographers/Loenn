local keyboardHelper = require("keyboard_helper")

local specialActivators = {
    ctrl = keyboardHelper.modifierControl,
    shift = keyboardHelper.modifierShift,
    alt = keyboardHelper.modifierAlt,
    gui = keyboardHelper.modifierGUI,
    command = keyboardHelper.modifierGUI,
    winkey = keyboardHelper.modifierGUI,

    plus = "+",
    minus = "-",
}

local hotkeyStruct = {}

-- TODO - Validate that the key constant exists?
-- Exact match means that ctrl + s will only be valid on ctrl + s, and not ctrl + alt + s and so on
function hotkeyStruct.sanitize(activator, exactMatch)
    exactMatch = exactMatch == nil or exactMatch
    local parts = string.split(activator, "+")
    local activators = {}

    local usedModifiers = {}

    for i, part <- parts do
        part = part:match("^%s*(.-)%s*$"):lower

        if specialActivators[part] then
            table.insert(activators, specialActivators[part])

            usedModifiers[part] = true

        else
            table.insert(activators, part)
        end
    end

    if exactMatch then
        for name, func <- keyboardHelper.nameToModifierFunction do
            if not usedModifiers[name] then
                table.insert(activators, function() return not specialActivators[name]() end)
            end
        end
    end

    return activators
end

function hotkeyStruct.hotkeyActive(hotkey)
    for i, part <- hotkey.activator do
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
    if hotkeyStruct.hotkeyActive(hotkey) then
        hotkey()
    end
end

function hotkeyStruct.callbackFirstActive(hotkeys)
    for i, hotkey <- hotkeys do
        if hotkey:active() then
            hotkey()

            return true, i
        end
    end

    return false, false
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

    return setmetatable(hotkey, hotkeyMt)
end

return hotkeyStruct