local inputHandler = {}

local function unhandledEvent()
    -- Do nothing
end

local inputDeviceMt = {
    __index = function() return unhandledEvent end
}

local reverseIterationEvents = {
    draw = true
}

function inputHandler.sendEvent(devices, event, ...)
    if event then
        local reversed = reverseIterationEvents[event]
        local deviceCount = #devices
        local start = reversed and deviceCount or 1
        local stop = reversed and 1 or deviceCount
        local step = reversed and -1 or 1

        for i = start, stop, step do
            local device = devices[i]

            if device._enabled then
                if event and device[event] then
                    local consumed = device[event](...)

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