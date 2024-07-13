local enums = require("consts.celeste_enums")
local songs = table.keys(enums.songs)

table.sort(songs)

local altMusic = {}

altMusic.name = "altMusicTrigger"
altMusic.category = "audio"
altMusic.fieldInformation = {
    track = {
        options = songs
    }
}
altMusic.placements = {
    name = "alt_music",
    data = {
        track = "",
        resetOnLeave = true
    }
}

return altMusic