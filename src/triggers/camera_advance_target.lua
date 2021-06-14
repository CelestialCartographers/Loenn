-- TODO Editing options: positionModeX, positionModeY

local cameraAdvanceTarget = {}

cameraAdvanceTarget.name = "cameraAdvanceTargetTrigger"
cameraAdvanceTarget.nodeLimits = {1, 1}
cameraAdvanceTarget.placements = {
    name = "camera_advance_target",
    data = {
        lerpStrengthX = 1.0,
        lerpStrengthY = 1.0,
        positionModeX = 0.0,
        positionModeY = 0.0,
        xOnly = false,
        yOnly = false
    }
}

return cameraAdvanceTarget