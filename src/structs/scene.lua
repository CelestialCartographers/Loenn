local utils = require("utils")
local inputDeviceHandler = require("input_device")

local sceneStruct = {}

local sceneMt = {}

function sceneMt.__index(self, key)
    -- Send event to input devices

    return function(self, ...)
        if self.inputDevices then
            inputDeviceHandler.sendEvent(self.inputDevices, key, ...)
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