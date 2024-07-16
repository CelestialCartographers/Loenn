local hotkeyStruct = require("structs.hotkey")
local standardHotkeys = require("standard_hotkeys")
local utils = require("utils")
local tools = require("tools")

local registeredHotkeys = {}
local hotkeyHandler = {}

function hotkeyHandler.addHotkey(scope, activator, callback, options)
    local hotkey

    if utils.typeof(scope) == "hotkey" then
        hotkey = scope
    end

    hotkey = hotkeyStruct.createHotkey(scope, activator, callback, options)

    table.insert(registeredHotkeys, hotkey)
end

function hotkeyHandler.addStandardHotkeys()
    standardHotkeys.addStandardHotkeys(hotkeyHandler)
end

function hotkeyHandler.reloadHotkeys()
    table.clear(registeredHotkeys)

    standardHotkeys.addStandardHotkeys(hotkeyHandler)
end

function hotkeyHandler.createHotkeyDevice()
    local device = {
        _type = "device",
        _enabled = true
    }

    device.hotkeys = registeredHotkeys

    function device.keypressed(key, scancode, isrepeat)
        local scopes = {"global"}

        tools.addHotkeyScopes(scopes)

        return hotkeyStruct.callbackFirstActive(registeredHotkeys, scopes)
    end

    return device
end

return hotkeyHandler