local booster = {}

booster.name = "booster"
booster.depth = -8500
booster.placements = {
    {
        name = "green",
        data = {
            red = false
        }
    },
    {
        name = "red",
        data = {
            red = true
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