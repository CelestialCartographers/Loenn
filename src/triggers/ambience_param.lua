local enums = require("consts.celeste_enums")

local ambienceParam = {}

ambienceParam.name = "ambienceParamTrigger"
ambienceParam.fieldInformation = {
    direction = {
        options = enums.trigger_position_modes
    }
}
ambienceParam.placements = {
    name = "ambience_param",
    data = {
        parameter = "",
        from = 0.0,
        to = 0.0,
        direction = "NoEffect"
    }
}

return ambienceParam