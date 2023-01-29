local enums = require("consts.celeste_enums")

local ambienceVolume = {}

ambienceVolume.name = "everest/ambienceVolumeTrigger"
ambienceVolume.associatedMods = {"Everest"}
ambienceVolume.fieldInformation = {
    direction = {
        options = enums.trigger_position_modes,
        editable = false
    }
}
ambienceVolume.placements = {
    name = "ambience_volume",
    data = {
        from = 0.0,
        to = 0.0,
        direction = "NoEffect"
    }
}

return ambienceVolume