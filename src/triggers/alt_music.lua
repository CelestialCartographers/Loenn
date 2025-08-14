local enums = require("consts.celeste_enums")

table.sort(songs)

local altMusic = {}

altMusic.name = "altMusicTrigger"
altMusic.category = "audio"
altMusic.fieldInformation = {
    track = {
        options = enums.alt_music
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
