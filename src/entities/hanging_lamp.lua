local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local hangingLamp = {}

hangingLamp.name = "hanginglamp"
hangingLamp.depth = 2000
hangingLamp.placements = {
    name = "hanging_lamp",
    data = {
        height = 16
    }
}

-- Manual offsets and justifications of the sprites
function hangingLamp.sprite(room, entity)
    local sprites = {}
    local height = math.max(entity.height or 0, 16)

    local topSprite = drawableSprite.fromTexture("objects/hanginglamp", entity)

    topSprite:setJustification(0, 0)
    topSprite:setOffset(0, 0)
    topSprite:useRelativeQuad(0, 0, 8, 8)

    table.insert(sprites, topSprite)

    for i = 0, height - 16, 8 do
        local middleSprite = drawableSprite.fromTexture("objects/hanginglamp", entity)

        middleSprite:setJustification(0, 0)
        middleSprite:setOffset(0, 0)
        middleSprite:addPosition(0, i)
        middleSprite:useRelativeQuad(0, 8, 8, 8)

        table.insert(sprites, middleSprite)
    end

    local bottomSprite = drawableSprite.fromTexture("objects/hanginglamp", entity)

    bottomSprite:setJustification(0, 0)
    bottomSprite:setOffset(0, 0)
    bottomSprite:addPosition(0, height - 8)
    bottomSprite:useRelativeQuad(0, 16, 8, 8)

    table.insert(sprites, bottomSprite)

    return sprites
end

function hangingLamp.selection(room, entity)
    return utils.rectangle(entity.x, entity.y, 8, math.max(entity.height, 16))
end

return hangingLamp