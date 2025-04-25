local enums = require("consts.celeste_enums")

local musicFade = {}

musicFade.name = "musicFadeTrigger"
musicFade.category = "audio"
musicFade.fieldInformation = {
    -- Legacy attribute, superceded by positionMode added by Everest
    direction = {
        options = enums.music_fade_trigger_directions,
        editable = false
    },
    positionMode = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
musicFade.placements = {
    name = "music_fade",
    data = {
        positionMode = "NoEffect",
        fadeA = 0.0,
        fadeB = 1.0,
        parameter = ""
    }
}

return musicFade