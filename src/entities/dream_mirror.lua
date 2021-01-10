local drawableSpriteStruct = require("structs.drawable_sprite")

local dreamMirror = {}

dreamMirror.name = "dreammirror"
dreamMirror.placements = {
    name = "Dream Mirror"
}

local frameTexture = "objects/mirror/frame"
local glassTexture = "objects/mirror/glassbreak00"

function dreamMirror.sprite(room, entity)
    local sprites = {}

    local frameSprite = drawableSpriteStruct.spriteFromTexture(frameTexture, entity)
    frameSprite:setJustification(0.5, 1.0)
    frameSprite.depth = 9000

    local glassSprite = drawableSpriteStruct.spriteFromTexture(glassTexture, entity)
    glassSprite:setJustification(0.5, 1.0)
    glassSprite.depth = 9500

    table.insert(sprites, frameSprite)
    table.insert(sprites, glassSprite)

    return sprites
end

return dreamMirror