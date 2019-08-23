local utils = require("utils")
local inputDeviceHandler = require("input_device")

local sceneStruct = {}

local sceneMt = {}

local sceneStructFunctions = {}

function sceneStructFunctions:propagateEvent(event, ...)
    if self.inputDevices then
        return inputDeviceHandler.sendEvent(self.inputDevices, event, ...)
    end
end

function sceneMt.__index(self, key)
    -- Send event to input devices

    if sceneStructFunctions[key] then
        return sceneStructFunctions[key]
    end

    if key:sub(1, 1) ~= "_" then
        return function(self, ...)
            return self:propagateEvent(key, ...)
        end
    end
end

function sceneStruct.create(scene)
    if not scene.name then
        error("Scene missing name.")
    end

    local res = utils.deepcopy(scene)

    res._type = "scene"
    res.inputDevices = {}

    return setmetatable(res, sceneMt)
end

return sceneStruct