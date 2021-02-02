-- TODO Editing options: positionModeX, positionModeY

local cameraAdvanceTarget = {}

cameraAdvanceTarget.name = "cameraAdvanceTargetTrigger"
cameraAdvanceTarget.placements = {
    name = "camera_advance_target",
    data = {
        lerpStrengthX = 0.0,
        lerpStrengthY = 0.0,
        positionModeX = 0.0,
        positionModeY = 0.0,
        xOnly = false,
        yOnly = false
    }
}

function cameraAdvanceTarget.nodeLimits(room, trigger)
    return 1, 1
end

return cameraAdvanceTarget