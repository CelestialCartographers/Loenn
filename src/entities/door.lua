local utils = require("utils")

local door = {}

local textures = {"wood", "metal"}
local textureOptions = {}

for _, texture in ipairs(textures) do
    textureOptions[utils.titleCase(texture)] = texture
end

door.name = "door"
door.depth = 8998
door.justification = {0.5, 1.0}
door.fieldInformation = {
    type = {
        options = textureOptions,
        editable = false
    }
}
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