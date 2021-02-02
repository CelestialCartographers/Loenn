-- TODO Editing options: positionMode

local cameraTarget = {}

cameraTarget.name = "cameraTargetTrigger"
cameraTarget.placements = {
    name = "camera_target",
    data = {
        lerpStrength = 0.0,
        positionMode = "NoEffect",
        xOnly = false,
        yOnly = false,
        deleteFlag = ""
    }
}

function cameraTarget.nodeLimits(room, trigger)
    return 1, 1
end

return cameraTarget