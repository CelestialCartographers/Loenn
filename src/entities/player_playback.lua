local playerPlayback = {}

-- Read from disk instead?
local baseGameTutorials = {
    "combo", "superwalljump", "too_close", "too_far",
    "wavedash", "wavedashppt"
}

playerPlayback.name = "playbackTutorial"
playerPlayback.depth = 0
playerPlayback.justification = {0.5, 1.0}
playerPlayback.texture = "characters/player/sitDown00"
playerPlayback.color = {0.8, 0.2, 0.2, 0.75}
playerPlayback.nodeLineRenderType = "line"
playerPlayback.nodeLimits = {0, 2}
playerPlayback.fieldInformation = {
    tutorial = {
        options = baseGameTutorials
    }
}
playerPlayback.placements = {
    name = "playback",
    data = {
        tutorial = ""
    }
}

return playerPlayback