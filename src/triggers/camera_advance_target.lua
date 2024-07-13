local enums = require("consts.celeste_enums")

local cameraAdvanceTarget = {}

cameraAdvanceTarget.name = "cameraAdvanceTargetTrigger"
cameraAdvanceTarget.category = "camera"
cameraAdvanceTarget.nodeLimits = {1, 1}
cameraAdvanceTarget.fieldInformation = {
    positionModeX = {
        options = enums.trigger_position_modes,
        editable = false
    },
    positionModeY = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
cameraAdvanceTarget.placements = {
    name = "camera_advance_target",
    data = {
        lerpStrengthX = 1.0,
        lerpStrengthY = 1.0,
        positionModeX = "NoEffect",
        positionModeY = "NoEffect",
        xOnly = false,
        yOnly = false
    }
}

return cameraAdvanceTarget