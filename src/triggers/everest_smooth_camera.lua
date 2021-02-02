-- TODO Editing options: positionMode

local everestSmoothCamera = {}

everestSmoothCamera.name = "everest/smoothCameraOffsetTrigger"
everestSmoothCamera.placements = {
    name = "smooth_camera",
    data = {
        offsetXFrom = 0.0,
        offsetXTo = 0.0,
        offsetYFrom = 0.0,
        offsetYTo = 0.0,
        positionMode = "NoEffect",
        onlyOnce = false,
        xOnly = false,
        yOnly = false
    }
}

return everestSmoothCamera