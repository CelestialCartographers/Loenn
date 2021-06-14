local drawableSprite = require("structs.drawable_sprite")

local lockBlock = {}

local textures = {
    wood = "objects/door/lockdoor00",
    temple_a = "objects/door/lockdoorTempleA00",
    temple_b = "objects/door/lockdoorTempleB00",
    moon = "objects/door/moonDoor11"
}

lockBlock.name = "lockBlock"
lockBlock.depth = 0
lockBlock.justification = {0.25, 0.25}
lockBlock.placements = {}

for name, texture in pairs(textures) do
    table.insert(lockBlock.placements, {
        name = name,
        data = {
            sprite = name,
            unlock_sfx = "",
            stepMusicProgress = false
        }
    })
end

function lockBlock.sprite(room, entity)
    local spriteName = entity.sprite or "wood"
    local texture = textures[spriteName] or textures["wood"]
    local sprite = drawableSprite.fromTexture(texture, entity)

    sprite:addPosition(16, 16)

    return sprite
end

return lockBlock
