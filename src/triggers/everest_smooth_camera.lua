local enums = require("consts.celeste_enums")

local everestSmoothCamera = {}

everestSmoothCamera.name = "everest/smoothCameraOffsetTrigger"
everestSmoothCamera.associatedMods = {"Everest"}
everestSmoothCamera.fieldInformation = {
    positionMode = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
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