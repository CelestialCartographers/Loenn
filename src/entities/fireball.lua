local fireball = {}

fireball.name = "fireBall"
fireball.depth = 0
fireball.nodeLineRenderType = "line"
fireball.texture = "objects/fireball/fireball01"
fireball.nodeLimits = {0, -1}
fireball.fieldInformation = {
    amount = {
        fieldType = "integer",
    }
}
fireball.placements = {
    name = "fireball",
    data = {
        amount = 3,
        offset = 0.0,
        speed = 1.0,
        notCoreMode = false
    }
}

return fireball