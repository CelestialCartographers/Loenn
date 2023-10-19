local fireball = {}

fireball.name = "fireBall"
fireball.depth = 0
fireball.nodeLineRenderType = "line"
fireball.nodeLimits = {1, -1}
fireball.fieldInformation = {
    amount = {
        fieldType = "integer",
    }
}
fireball.placements = {
    {
        name = "fireball",
        data = {
            amount = 3,
            offset = 0.0,
            speed = 1.0,
            notCoreMode = false
        }
    },
    {
        name = "iceball",
        data = {
            amount = 3,
            offset = 0.0,
            speed = 1.0,
            notCoreMode = true
        }
    }
}

function fireball.texture(room, entity)
    if entity.notCoreMode then
        return "objects/fireball/fireball09"

    else
        return "objects/fireball/fireball01"
    end
end

return fireball
