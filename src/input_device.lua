local inputHandler = {}

inputHandler.inputDevices = $()

local function unhandledEvent()
    -- Do nothing
end

local inputDeviceMt = {
    __index = function() return unhandledEvent end
}

function inputHandler.sendEvent(event, ...)
    if event then
        for i, device <- inputHandler.inputDevices do
            if device._enabled then
                local args = {...} or {}
                device[event](unpack(args))
            end
        end
    end
end

function inputHandler.newInputDevice(t)
    local newDevice = setmetatable(t, inputDeviceMt)
    inputHandler.inputDevices += newDevice

    return newDevice
end

return inputHandler