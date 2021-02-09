-- TODO - Support nodes

local strawberry = {}

strawberry.name = "strawberry"
strawberry.depth = -100

function strawberry.texture(room, entity)
    local moon = entity.moon
    local winged = entity.winged

    if moon then
        if winged then
            return "collectables/moonBerry/ghost00"

        else
            return "collectables/moonBerry/normal00"
        end

    else
        if winged then
            return "collectables/strawberry/wings01"

        else
            return "collectables/strawberry/normal00"
        end
    end
end

strawberry.placements = {
    {
        name = "normal",
        data = {
            winged = false,
            moon = false
        },
    },
    {
        name = "normal_winged",
        data = {
            winged = true,
            moon = false
        },
    },
    {
        name = "moon",
        data = {
            winged = false,
            moon = true
        },
    }
}

return strawberry