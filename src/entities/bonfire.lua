local enums = require("consts.celeste_enums")

local bonfire = {}

bonfire.name = "bonfire"
bonfire.depth = -5
bonfire.justification = {0.5, 1.0}
bonfire.fieldInformation = {
    mode = {
        options = enums.bonfire_modes,
        editable = false
    }
}
bonfire.placements = {
    name = "bonfire",
    data = {
        mode = "Lit"
    }
}

 function bonfire.texture(room, entity)
    local mode = string.lower(entity.mode or "lit")

    if mode == "lit" then
        return "objects/campfire/fire08"

    elseif mode == "smoking" then
        return "objects/campfire/smoking04"

    else
        return "objects/campfire/fire00"
    end
end

return bonfire