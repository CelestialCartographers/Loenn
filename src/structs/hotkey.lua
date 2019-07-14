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
function hotkeyStruct.sanitize(activator)
    local parts = string.split(activator, "+")
    local activators = $()

    for i, part <- parts do
        part = part:match("^%s*(.-)%s*$"):lower

        if specialActivators[part] then
            activators += specialActivators[part]

        else
            activators += part
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

function hotkeyMt.__call(self) 
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