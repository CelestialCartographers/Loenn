local strawberry = {}

strawberry.name = "goldenBerry"
strawberry.depth = -100
strawberry.nodeLineRenderType = "fan"
strawberry.nodeLimits = {0, -1}

function strawberry.texture(room, entity)
    local winged = entity.winged
    local hasNodes = entity.nodes and #entity.nodes > 0

    if winged then
        if hasNodes then
            return "collectables/ghostgoldberry/wings01"

        else
            return "collectables/goldberry/wings01"
        end

    else
        if hasNodes then
            return "collectables/ghostgoldberry/idle00"

        else
            return "collectables/goldberry/idle00"
        end
    end
end

function strawberry.nodeTexture(room, entity)
    local hasNodes = entity.nodes and #entity.nodes > 0

    if hasNodes then
        return "collectables/goldberry/seed00"
    end
end

strawberry.placements = {
    {
        name = "golden",
        data = {
            winged = false,
            moon = false
        },
    },
    {
        name = "golden_winged",
        data = {
            winged = true,
            moon = false
        }
    }
}

return strawberry