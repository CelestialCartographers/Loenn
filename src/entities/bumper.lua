local bumper = {}

bumper.name = "bigSpinner"
bumper.depth = 0
bumper.nodeLineRenderType = "line"
bumper.texture = "objects/Bumper/Idle22"

bumper.placements = {
    name = "bumper"
}

function bumper.nodeLimits(room, entity)
    return 0, 1
end

return bumper