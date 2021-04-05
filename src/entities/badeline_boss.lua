local badelineBoss = {}

badelineBoss.name = "finalBoss"
badelineBoss.depth = 0
badelineBoss.nodeLineRenderType = "line"
badelineBoss.texture = "characters/badelineBoss/charge00"

badelineBoss.placements = {
    name = "boss",
    data = {
        patternIndex = 1,
        startHit = false,
        cameraPastY = 120,
        cameraLockY = true,
        canChangeMusic = true
    }
}

function badelineBoss.nodeLimits(room, entity)
    return 0, -1
end

return badelineBoss