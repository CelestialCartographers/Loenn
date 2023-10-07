local flingBird = {}

flingBird.name = "flingBird"
flingBird.depth = 0
flingBird.nodeLineRenderType = "line"
flingBird.texture = "characters/bird/Hover04"
flingBird.nodeLimits = {1, -1}
flingBird.placements = {
    name = "fling_bird",
    data = {
        waiting = false
    }
}

return flingBird