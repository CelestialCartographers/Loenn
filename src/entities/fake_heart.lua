local enums = require("consts.celeste_enums")

local fakeHeart = {}

local textures = {
    Normal = "collectables/heartGem/0/00",
    BSide = "collectables/heartGem/1/00",
    CSide = "collectables/heartGem/2/00",
    Random = "collectables/heartGem/0/00"
}

fakeHeart.name = "fakeHeart"
fakeHeart.depth = -2000000
fakeHeart.fieldInformation = {
    color = {
        options = enums.everest_fake_heart_colors,
        editable = false
    }
}
fakeHeart.placements = {
    name = "crystal_heart",
    data = {
        color = "Random"
    }
}

function fakeHeart.texture(room, entity)
    local color = entity.color or "Normal"

    return textures[color] or textures.Normal
end

return fakeHeart