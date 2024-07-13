local enums = require("consts.celeste_enums")

local bloomFade = {}

bloomFade.name = "bloomFadeTrigger"
bloomFade.category = "visual"
bloomFade.fieldInformation = {
    positionMode = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
bloomFade.placements = {
    name = "bloom_fade",
    data = {
        bloomAddFrom = 0.0,
        bloomAddTo = 0,
        positionMode = "NoEffect"
    }
}

return bloomFade