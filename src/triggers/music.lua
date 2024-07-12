local enums = require("consts.celeste_enums")
local songs = table.keys(enums.songs)

table.sort(songs)

local music = {}

music.name = "musicTrigger"
music.category = "audio"
music.fieldInformation = {
    death_count = {
        fieldType = "integer",
    },
    track = {
        options = songs
    }
}
music.placements = {
    name = "music",
    data = {
        track = "",
        resetOnLeave = true,
        progress = 0
    }
}

return music