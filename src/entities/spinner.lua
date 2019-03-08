local entities = require("entities")

local spinner = {}

spinner.name = "spinner"

function spinner.sprite(room, entity)
    local color = entity.color or "blue"
    local dusty = entity.dusty

    if dusty then
        local textureBase = "danger/dustcreature/base00"
        local textureCenter = "danger/dustcreature/center00"

        return {
            entities.spriteFromTexture(textureBase, entity),
            entities.spriteFromTexture(textureCenter, entity),
        }

    else
        local texture = "danger/crystal/fg_" .. string.lower(color) .. "00"

        return entities.spriteFromTexture(texture, entity)
    end
end

return spinner