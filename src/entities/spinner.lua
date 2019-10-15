local drawableSpriteStruct = require("structs.drawable_sprite")

local spinner = {}

function spinner.depth(room, entity)
    return entity.dusty and -50 or -8500
end

function spinner.sprite(room, entity)
    local color = entity.color or "Blue"
    local dusty = entity.dusty

    if dusty then
        local textureBase = "danger/dustcreature/base00"
        local textureCenter = "danger/dustcreature/center00"

        return {
            drawableSpriteStruct.spriteFromTexture(textureBase, entity),
            drawableSpriteStruct.spriteFromTexture(textureCenter, entity),
        }

    else
        local texture = "danger/crystal/fg_" .. string.lower(color) .. "00"

        return drawableSpriteStruct.spriteFromTexture(texture, entity)
    end
end

return spinner