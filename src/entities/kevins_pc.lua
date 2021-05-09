local drawableSprite = require("structs.drawable_sprite")

local kevinsPc = {}

kevinsPc.name = "kevins_pc"
kevinsPc.depth = 8999
kevinsPc.placements = {
    name = "kevins_pc"
}

local computerTexture = "objects/kevinspc/pc"
local spectogramTexture = "objects/kevinspc/spectogram"

function kevinsPc.sprite(room, entity)
    local computerSprite = drawableSprite.spriteFromTexture(computerTexture, entity)
    local spectogramSprite = drawableSprite.spriteFromTexture(spectogramTexture, entity)

    computerSprite:setJustification(0.5, 1.0)

    spectogramSprite:setJustification(0.0, 0.0)
    spectogramSprite:addPosition(-16, -39)
    spectogramSprite:useRelativeQuad(0, 0, 32, 18)

    local sprites = {
        computerSprite,
        spectogramSprite
    }

    return sprites
end

return kevinsPc