local inputHandler = {}

local function unhandledEvent()
    -- Do nothing
end

local inputDeviceMt = {
    __index = function() return unhandledEvent end
}

function inputHandler.sendEvent(devices, event, ...)
    if event then
        for i, device <- devices do
            if device._enabled then
                if event and device[event] then
                    local args = {...} or {}
                    local consumed = device[event](unpack(args))

                    if consumed then
                        return true
                    end
                end
            end
        end
    end

    return false
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