local bonfire = {}

bonfire.name = "bonfire"
bonfire.depth = -5
bonfire.justification = {0.5, 1.0}
bonfire.placements = {
    name = "bonfire"
}

 function bonfire.texture(room, entity)
    local mode = entity.mode

    if mode == "lit" then
        return "objects/campfire/fire08"

    elseif mode == "smoking" then
        return "objects/campfire/smoking04"

    else
        return "objects/campfire/fire00"
    end
end

return bonfire