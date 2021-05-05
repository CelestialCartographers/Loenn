local birdPath = {}

birdPath.name = "birdPath"
birdPath.depth = 0
birdPath.nodeLineRenderType = "line"
birdPath.texture = "characters/bird/flyup00"
birdPath.nodeLimits = {0, -1}
birdPath.placements = {
    name = "bird_path",
    data = {
        only_once = false,
        onlyIfLeft = false,
        speedMult = 1.0
    }
}

return birdPath