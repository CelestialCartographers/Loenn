local coreToggle = {}

coreToggle.name = "coreModeToggle"
coreToggle.depth = 2000

function coreToggle.texture(room, entity)
    local onlyIce = entity.onlyIce
    local onlyFire = entity.onlyFire

    if onlyIce then
        return "objects/coreFlipSwitch/switch13"

    elseif onlyFire then
        return "objects/coreFlipSwitch/switch15"

    else
        return "objects/coreFlipSwitch/switch01"
    end
end

coreToggle.placements = {
    {
        name = "both",
        data = {
            onlyIce = false,
            onlyFire = false,
            persistent = false
        },
    },
    {
        name = "fire",
        data = {
            onlyIce = false,
            onlyFire = true,
            persistent = false
        },
    },
    {
        name = "ice",
        data = {
            onlyIce = true,
            onlyFire = false,
            persistent = false
        },
    }
}

return coreToggle