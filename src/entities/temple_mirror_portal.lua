local drawableSprite = require("structs.drawable_sprite")

local templeMirrorPortal = {}

templeMirrorPortal.name = "templeMirrorPortal"
templeMirrorPortal.depth = -1999
templeMirrorPortal.placements = {
    name = "temple_mirror_portal",
}

local frameTexture = "objects/temple/portal/portalframe"
local curtainTexture = "objects/temple/portal/portalcurtain00"
local torchTexture = "objects/temple/portal/portaltorch00"

local torchOffset = 90

function templeMirrorPortal.sprite(room, entity)
    local frameSprite = drawableSprite.spriteFromTexture(frameTexture, entity)
    local curtainSprite = drawableSprite.spriteFromTexture(curtainTexture, entity)
    local torchSpriteLeft = drawableSprite.spriteFromTexture(torchTexture, entity)
    local torchSpriteRight = drawableSprite.spriteFromTexture(torchTexture, entity)

    torchSpriteLeft:addPosition(-torchOffset, 0)
    torchSpriteLeft:setJustification(0.5, 0.75)

    torchSpriteRight:addPosition(torchOffset, 0)
    torchSpriteRight:setJustification(0.5, 0.75)

    local sprites = {
        frameSprite,
        curtainSprite,
        torchSpriteLeft,
        torchSpriteRight
    }

    return sprites
end


return templeMirrorPortal