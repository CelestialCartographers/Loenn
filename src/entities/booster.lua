local booster = {}

booster.name = "booster"
booster.depth = -8500
booster.placements = {
    {
        name = "green",
        data = {
            red = false,
            ch9_hub_booster = false
        }
    },
    {
        name = "red",
        data = {
            red = true,
            ch9_hub_booster = false
        }
    }
}

function booster.texture(room, entity)
    local red = entity.red

    if red then
        return "objects/booster/boosterRed00"

    else
        return "objects/booster/booster00"
    end
end

return booster