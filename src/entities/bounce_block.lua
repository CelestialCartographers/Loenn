local drawableNinePatch = require("structs.drawable_nine_patch")
local drawableSprite = require("structs.drawable_sprite")

local bounceBlock = {}

bounceBlock.name = "bounceBlock"
bounceBlock.depth = 8990
bounceBlock.minimumSize = {16, 16}
bounceBlock.placements = {
    name = "bounce_block",
    data = {
        width = 16,
        height = 16,
        notCoreMode = false
    }
}

local ninePatchOptions = {
    mode = "fill",
    borderMode = "repeat",
    fillMode = "repeat"
}

local blockTexture = "objects/BumpBlockNew/fire00"
local crystalTexture = "objects/BumpBlockNew/fire_center00"

function bounceBlock.sprite(room, entity)
    local x, y = entity.x or 0, entity.y or 0
    local width, height = entity.width or 24, entity.height or 24

    local ninePatch = drawableNinePatch.fromTexture(blockTexture, ninePatchOptions, x, y, width, height)
    local crystalSprite = drawableSprite.fromTexture(crystalTexture, entity)
    local sprites = ninePatch:getDrawableSprite()

    crystalSprite:addPosition(math.floor(width / 2), math.floor(height / 2))
    table.insert(sprites, crystalSprite)

    return sprites
end

return bounceBlock