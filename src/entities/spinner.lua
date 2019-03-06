local entities = require("entities")

return {
    name = "spinner",
    sprite = function(room, entity)
        local color = entity.color or "blue"
        local dusty = entity.dusty

        local texture = "danger/crystal/fg_" .. string.lower(color) .. "00"

        return entities.spriteFromTexture(texture, entity)
    end
}