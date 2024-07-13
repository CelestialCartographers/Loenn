local enums = require("consts.celeste_enums")

local lightFade = {}

lightFade.name = "lightFadeTrigger"
lightFade.category = "visual"
lightFade.fieldInformation = {
    positionMode = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
lightFade.placements = {
    name = "light_fade",
    data = {
        lightAddFrom = 0.0,
        lightAddTo = 0.0,
        positionMode = "NoEffect"
    }
}

return lightFade