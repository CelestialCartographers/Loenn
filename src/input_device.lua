local inputHandler = {}

local function unhandledEvent()
    -- Do nothing
end

local inputDeviceMt = {
    __index = function() return unhandledEvent end
}

-- TODO - Add a way to specify what device group we are sending to?
function inputHandler.sendEvent(devices, event, ...)
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

-- Use inputDeviceMt if no other metatable is already set for the device
function inputHandler.newInputDevice(devices, device)
    if not getmetatable(device) then
        device = setmetatable(device, inputDeviceMt)
    end

    table.insert(devices, device)

    return device
end

return inputHandler