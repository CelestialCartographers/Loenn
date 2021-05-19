-- TODO Editing options: positionMode

local cameraTarget = {}

cameraTarget.name = "cameraTargetTrigger"
cameraTarget.nodeLimits = {1, 1}
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