local enums = require("consts.celeste_enums")

local moonGlitchBackground = {}

moonGlitchBackground.name = "moonGlitchBackgroundTrigger"
moonGlitchBackground.fieldInformation = {
    duration = {
        options = enums.moon_glitch_background_trigger_durations,
        editable = false
    }
}
moonGlitchBackground.placements = {
    name = "moon_glitch_background",
    data = {
        duration = "Short",
        stay = false,
        glitch = true
    }
}

return moonGlitchBackground