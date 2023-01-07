local puffer = {}

puffer.name = "eyebomb"
puffer.depth = 0
puffer.texture = "objects/puffer/idle00"
puffer.placements = {
    {
        name = "left",
        data = {
            right = false
        }
    },
    {
        name = "right",
        data = {
            right = true
        }
    }
}

function puffer.scale(room, entity)
    local right = entity.right

    return right and 1 or -1, 1
end

function puffer.flip(room, entity, horizontal, vertical)
    if horizontal then
        entity.right = not entity.right
    end

    return horizontal
end

return puffer