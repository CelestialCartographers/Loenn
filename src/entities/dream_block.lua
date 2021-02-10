local dreamBlock = {}

dreamBlock.name = "dreamBlock"
dreamBlock.fillColor = {0.0, 0.0, 0.0}
dreamBlock.borderColor = {1.0, 1.0, 1.0}
dreamBlock.placements = {
    name = "dream_block",
    data = {
        fastMoving = false,
        below = false,
        width = 8,
        height = 8
    }
}

function dreamBlock.depth(room, entity)
    return entity.below and 5000 or -11000
end

function dreamBlock.nodeLimits(room, entity)
    return 0, 1
end

return dreamBlock