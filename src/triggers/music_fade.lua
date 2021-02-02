-- TODO Editing options: direction

local musicFade = {}

musicFade.name = "musicFadeTrigger"
musicFade.placements = {
    name = "music_fade",
    data = {
        direction = "leftToRight",
        fadeA = 0.0,
        fadeB = 1.0,
        parameter = ""
    }
}

return musicFade