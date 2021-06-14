local drawableSpriteStruct = require("structs.drawable_sprite")

local defaultSpinnerColor = "blue"
local unknownSpinnerColor = "white"
local spinnerColors = {
    "blue",
    "red",
    "purple",
    "core",
    "rainbow"
}

local spinner = {}

spinner.name = "spinner"
spinner.placements = {
    {
        name = "dust_sprite",
        data = {
            color = "blue",
            dust = true,
            attachToSolid = false
        }
    }
}

for _, color in ipairs(spinnerColors) do
    table.insert(spinner.placements, {
        name = color,
        data = {
            color = color,
            dust = false,
            attachToSolid = false
        }
    })
end

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
            drawableSpriteStruct.fromTexture(textureBase, entity),
            drawableSpriteStruct.fromTexture(textureCenter, entity),
        }

    else
        -- Prevent color from spinner to tint the drawable sprite
        local position = {
            x = entity.x,
            y = entity.y
        }

        local texture = "danger/crystal/fg_" .. string.lower(color) .. "00"
        local sprite = drawableSpriteStruct.fromTexture(texture, position)

        -- Check if texture color exists, otherwise use default color
        -- Needed because Rainbow and Core colors doesn't have textures
        if sprite then
            return sprite

        else
            texture = "danger/crystal/fg_" .. string.lower(unknownSpinnerColor) .. "00"

            return drawableSpriteStruct.fromTexture(texture, position)
        end
    end
end

return spinner