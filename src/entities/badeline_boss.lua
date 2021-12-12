local badelineBoss = {}

badelineBoss.name = "finalBoss"
badelineBoss.depth = 0
badelineBoss.nodeLineRenderType = "line"
badelineBoss.texture = "characters/badelineBoss/charge00"
badelineBoss.nodeLimits = {0, -1}
badelineBoss.fieldInformation = {
    patternIndex = {
        fieldType = "integer",
    }
}
badelineBoss.placements = {
    name = "boss",
    data = {
        patternIndex = 1,
        startHit = false,
        cameraPastY = 120.0,
        cameraLockY = true,
        canChangeMusic = true
    }
}

return badelineBoss