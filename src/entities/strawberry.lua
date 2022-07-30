local strawberry = {}

strawberry.name = "strawberry"
strawberry.depth = -100
strawberry.nodeLineRenderType = "fan"
strawberry.nodeLimits = {0, -1}
strawberry.fieldInformation = {
    order = {
        fieldType = "integer",
    },
    checkpointID = {
        fieldType = "integer"
    }
}

function strawberry.texture(room, entity)
    local moon = entity.moon
    local winged = entity.winged
    local hasNodes = entity.nodes and #entity.nodes > 0

    if moon then
        if winged or hasNodes then
            return "collectables/moonBerry/ghost00"

        else
            return "collectables/moonBerry/normal00"
        end

    else
        if winged then
            if hasNodes then
                return "collectables/ghostberry/wings01"

            else
                return "collectables/strawberry/wings01"
            end

        else
            if hasNodes then
                return "collectables/ghostberry/idle00"

            else
                return "collectables/strawberry/normal00"
            end
        end
    end
end

function strawberry.nodeTexture(room, entity)
    local hasNodes = entity.nodes and #entity.nodes > 0

    if hasNodes then
        return "collectables/strawberry/seed00"
    end
end

strawberry.placements = {
    {
        name = "normal",
        data = {
            winged = false,
            moon = false,
            checkpointID = -1,
            order = -1
        },
    },
    {
        name = "normal_winged",
        data = {
            winged = true,
            moon = false,
            checkpointID = -1,
            order = -1
        },
    },
    {
        name = "moon",
        data = {
            winged = false,
            moon = true,
            checkpointID = -1,
            order = -1
        },
    }
}

return strawberry