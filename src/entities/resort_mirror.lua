local drawableSprite = require("structs.drawable_sprite")

local glassTexture = "objects/mirror/glassbreak00"
local frameTexture = "objects/mirror/resortframe"

local resortMirror = {}

resortMirror.name = "resortmirror"
resortMirror.placements = {
    name = "mirror"
}

function resortMirror.rectangle(room, entity)
    local frameSprite = drawableSprite.fromTexture(frameTexture, entity)

    frameSprite:setJustification(0.5, 1.0)

    return frameSprite:getRectangle()
end

function resortMirror.sprite(room, entity)
    local glassSprite = drawableSprite.fromTexture(glassTexture, entity)
    local frameSprite = drawableSprite.fromTexture(frameTexture, entity)

    glassSprite.depth = 9500
    frameSprite.depth = 9000

    frameSprite:setJustification(0.5, 1.0)

    -- Slight offset for visible portion of frame
    local frameWidth = frameSprite.meta.width - 2
    local frameHeight = frameSprite.meta.height - 8

    local glassWidth = glassSprite.meta.width
    local glassHeight = glassSprite.meta.height

    local quadX = math.floor((glassWidth - frameWidth) / 2)
    local quadY = glassHeight - frameHeight

    glassSprite:useRelativeQuad(quadX, quadY, frameWidth, frameHeight)
    glassSprite:addPosition(-frameWidth / 2, -frameHeight)

    return {
        glassSprite,
        frameSprite
    }
end

return resortMirror