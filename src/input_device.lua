local inputDevices = $()

local function unhandledEvent()
    -- Do nothing
end

local inputDeviceMt = {
    __index = function() return unhandledEvent end
}

local function sendEvent(event, ...)
    if event then
        for i, device <- inputDevices do
            local args = {...} or {}
            device[event](unpack(args))
        end
    end
end

local function newInputDevice(t, unhandled)
    local newDevice = setmetatable(t, inputDeviceMt)
    inputDevices += newDevice

    return newDevice
end

return {
    newInputDevice = newInputDevice,
    sendEvent = sendEvent
}