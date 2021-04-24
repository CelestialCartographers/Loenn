local door = {}

local textures = {"wood", "metal"}

door.name = "door"
door.depth = 8998
door.justification = {0.5, 1.0}
door.placements = {}

for i, texture in ipairs(textures) do
    door.placements[i] = {
        name = texture,
        data = {
            ["type"] = texture
        }
    }
end

function door.texture(room, entity)
    local variant = entity["type"]

    if variant == "wood" then
        return "objects/door/door00"

    else
        return "objects/door/metaldoor00"
    end
end

return door