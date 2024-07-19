local hotkeyStruct = require("structs.hotkey")
local standardHotkeys = require("standard_hotkeys")
local utils = require("utils")
local tools = require("tools")

local registeredHotkeys = {}
local hotkeyHandler = {}

function hotkeyHandler.removeHotkey(scope, activator)
    if utils.typeof(scope) == "hotkey" then
        activator = scope._rawActivator
        scope = scope.scope
    end

    for i, target in ipairs(registeredHotkeys) do
        if target.scope == scope and target._rawActivator == activator then
            table.remove(registeredHotkeys, i)

            return target
        end
    end
end

function hotkeyHandler.addHotkey(scope, activator, callback, options)
    local hotkey

    if utils.typeof(scope) == "hotkey" then
        hotkey = scope
    end

    -- Remove any previously registered hotkeys to same scope and activator
    hotkeyHandler.removeHotkey(scope, activator)

    hotkey = hotkeyStruct.createHotkey(scope, activator, callback, options)

    table.insert(registeredHotkeys, hotkey)

    return hotkey
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