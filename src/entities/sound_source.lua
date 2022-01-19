local enums = require("consts.celeste_enums")
local environmentalSounds = table.keys(enums.environmental_sounds)

table.sort(environmentalSounds)

local soundSource = {}

soundSource.name = "soundSource"
soundSource.depth = 0
soundSource.texture = "@Internal@/sound_source"
soundSource.fieldInformation = {
    sound = {
        options = environmentalSounds
    }
}
soundSource.placements = {
    name = "sound_source",
    data = {
        sound = ""
    }
}

return soundSource