-- TODO Editing options: track

local music = {}

music.name = "musicTrigger"
music.placements = {
    name = "music",
    data = {
        track = "",
        resetOnLeave = true,
        progress = 0
    }
}

return music