local playerPlayback = {}

playerPlayback.name = "playbackTutorial"
playerPlayback.depth = 0
playerPlayback.justification = {0.5, 1.0}
playerPlayback.texture = "characters/player/sitDown00"
playerPlayback.color = {0.8, 0.2, 0.2, 0.75}
playerPlayback.nodeLimits = {0, 2}
playerPlayback.placements = {
    name = "playback",
    data = {
        tutorial = ""
    }
}

return playerPlayback