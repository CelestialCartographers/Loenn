local inputHandler = {}

inputHandler.inputDevices = {}

local function unhandledEvent()
    -- Do nothing
end

local inputDeviceMt = {
    __index = function() return unhandledEvent end
}

-- TODO - Add devices arg
function inputHandler.sendEvent(event, ...)
    local devices = inputHandler.inputDevices

    if event then
        for i, device <- devices do
            if device._enabled then
                local args = {...} or {}
                local consumed = device[event](unpack(args))

                if consumed then
                    return
                end
            end
        end
    end
end

function inputHandler.newInputDevice(device, devices)
    local devices = devices or inputHandler.inputDevices
    local newDevice = setmetatable(device, inputDeviceMt)

    table.insert(devices, newDevice)

    return newDevice
end

return inputHandler