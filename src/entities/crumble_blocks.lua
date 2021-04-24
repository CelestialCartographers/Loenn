local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local crumbleBlock = {}

local textures = {
    "default", "cliffside"
}

crumbleBlock.name = "crumbleBlock"
crumbleBlock.depth = 0
crumbleBlock.placements = {}

for _, texture in ipairs(textures) do
    table.insert(crumbleBlock.placements, {
        name = texture,
        data = {
            width = 8,
            texture = texture
        }
    })
end

-- Manual offsets and justifications of the sprites
function crumbleBlock.sprite(room, entity)
    local sprites = {}

    local width = math.max(entity.width or 0, 8)
    local renderOffset = 0

    local variant = entity.texture or "default"
    local texture = "objects/crumbleBlock/" .. variant

    while width >= 32 do
        local sprite = drawableSprite.spriteFromTexture(texture, entity)

        sprite:setJustification(0, 0)
        sprite:addPosition(renderOffset, 0)

        table.insert(sprites, sprite)

        width -= 32
        renderOffset += 32
    end

    if width > 0 then
        local sprite = drawableSprite.spriteFromTexture(texture, entity)

        sprite:setJustification(0, 0)
        sprite:addPosition(renderOffset, 0)
        sprite:useRelativeQuad(0, 0, width, 8)

        table.insert(sprites, sprite)
    end

    return sprites
end

function crumbleBlock.selection(room, entity)
    return utils.rectangle(entity.x, entity.y, math.max(entity.width or 0, 8), 8)
end

return crumbleBlock