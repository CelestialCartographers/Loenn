local hotkeyStruct = require("structs.hotkey")
local standardHotkeys = require("standard_hotkeys")
local utils = require("utils")

local hotkeyHandler = {}

hotkeyHandler.registeredHotkeys = {}

function hotkeyHandler.removeHotkey(scope, activator)
    if utils.typeof(scope) == "hotkey" then
        activator = scope._rawActivator
        scope = scope.scope
    end

    for i, target in ipairs(hotkeyHandler.registeredHotkeys) do
        if target.scope == scope and target._rawActivator == activator then
            table.remove(hotkeyHandler.registeredHotkeys, i)

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

    table.insert(hotkeyHandler.registeredHotkeys, hotkey)

    return hotkey
end

function hotkeyHandler.addStandardHotkeys()
    standardHotkeys.addStandardHotkeys(hotkeyHandler)
end

function hotkeyHandler.reloadHotkeys()
    table.clear(hotkeyHandler.registeredHotkeys)

    standardHotkeys.addStandardHotkeys(hotkeyHandler)
end

function hotkeyHandler.createHotkeyDevice()
    local device = {
        _type = "device",
        _enabled = true
    }

    device.hotkeys = hotkeyHandler.registeredHotkeys

    -- Only handle global hotkeys here, let other devices do scoped ones
    function device.keypressed(...)
        local scopes = {"global"}

        return hotkeyStruct.callbackFirstActive(hotkeyHandler.registeredHotkeys, scopes, ...)
    end

    return device
end

return hotkeyHandler