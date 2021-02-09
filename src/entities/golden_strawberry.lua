-- TODO - Support nodes

local strawberry = {}

strawberry.name = "goldenBerry"
strawberry.depth = -100

function strawberry.texture(room, entity)
    local winged = entity.winged

    if winged then
        return "collectables/goldberry/wings01"

    else
        return "collectables/goldberry/idle00"
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