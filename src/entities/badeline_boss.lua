local badelineBoost = {}

badelineBoost.name = "badelineBoost"
badelineBoost.depth = -1000000
badelineBoost.nodeLineRenderType = "line"
badelineBoost.texture = "objects/badelineboost/idle00"

badelineBoost.placements = {
    name = "boost",
    data = {
        lockCamera = true,
        canSkip = false,
        finalCh9Boost = false,
        finalCh9GoldenBoost = false,
        finalCh9Dialog = false
    }
}

function badelineBoost.nodeLimits(room, entity)
    return 0, -1
end

return badelineBoost