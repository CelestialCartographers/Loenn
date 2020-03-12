local drawableSpriteStruct = require("structs.drawable_sprite")

local defaultSpinnerColor = "Blue"

local spinner = {}

function spinner.depth(room, entity)
    return entity.dusty and -50 or -8500
end

function spinner.sprite(room, entity)
    local color = entity.color or defaultSpinnerColor
    local dusty = entity.dusty

    if dusty then
        local textureBase = "danger/dustcreature/base00"
        local textureCenter = "danger/dustcreature/center00"

        return {
            drawableSpriteStruct.spriteFromTexture(textureBase, entity),
            drawableSpriteStruct.spriteFromTexture(textureCenter, entity),
        }

    else
        -- Prevent color from spinner to tint the drawable sprite
        local position = {
            x = entity.x,
            y = entity.y
        }

        local texture = "danger/crystal/fg_" .. string.lower(color) .. "00"
        local sprite = drawableSpriteStruct.spriteFromTexture(texture, position)

        -- Check if texture color exists, otherwise use default color
        -- Needed because Rainbow and Core colors doesn't have textures
        if sprite.meta then
            return sprite

        else
            texture = "danger/crystal/fg_" .. string.lower(defaultSpinnerColor) .. "00"

            return drawableSpriteStruct.spriteFromTexture(texture, position)
        end
    end
end

return spinner