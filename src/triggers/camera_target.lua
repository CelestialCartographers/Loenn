local enums = require("consts.celeste_enums")

local cameraTarget = {}

cameraTarget.name = "cameraTargetTrigger"
cameraTarget.category = "camera"
cameraTarget.nodeLimits = {1, 1}
cameraTarget.fieldInformation = {
    positionMode = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
cameraTarget.placements = {
    name = "camera_target",
    data = {
        lerpStrength = 1.0,
        positionMode = "NoEffect",
        xOnly = false,
        yOnly = false,
        deleteFlag = ""
    }
}

return cameraTarget