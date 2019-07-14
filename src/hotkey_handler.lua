local hotkeyStruct = require("structs/hotkey")
local utils = require("utils")

local defaultHotkeys = {}
local hotkeyHandler = {}

-- Register hotkey to hotkey group registerHotkey(hotkey[, group])
-- Make a hotkey and then add to hotkey group registerHotkey(activator, callback[, group])
function hotkeyHandler.registerHotkey(hotkey, hotkeys)
    hotkeys = hotkeys or defaultHotkeys

    table.insert(hotkeys, hotkey)
end

function hotkeyHandler.createAndRegisterHotkey(activator, callback, hotkeys)
    hotkeyHandler.registerHotkey(hotkeyStruct.createHotkey(activator, callback), hotkeys)
end

function hotkeyHandler.createHotkeyDevice(hotkeys)
    local device = {
        _type = "device",
        _enabled = true
    }

    device.hotkeys = hotkeys or defaultHotkeys

    function device.keypressed(key, scancode, isrepeat)
        return hotkeyStruct.callbackFirstActive(device.hotkeys)
    end

    return device
end

return hotkeyHandler