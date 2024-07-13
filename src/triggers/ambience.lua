local enums = require("consts.celeste_enums")
local ambientSounds = table.keys(enums.ambient_sounds)

table.sort(ambientSounds)

local ambience = {}

ambience.name = "everest/ambienceTrigger"
ambience.category = "audio"
ambience.associatedMods = {"Everest"}
ambience.fieldInformation = {
    track = {
        options = ambientSounds
    }
}
ambience.placements = {
    name = "ambience",
    data = {
        track = "",
        resetOnLeave = true
    }
}

return ambience