-- Only add placement for the Everest memorial
-- Everest version allows custom dialog and sprite

local defaultMemorialTexture = "scenery/memorial/memorial"

local memorial = {}

memorial.name = "memorial"
memorial.depth = 100
memorial.texture = defaultMemorialTexture
memorial.justification = {0.5, 1.0}

local everestMemorial = {}

everestMemorial.name = "everest/memorial"
everestMemorial.depth = 100
everestMemorial.justification = {0.5, 1.0}
everestMemorial.placements = {
    name = "memorial",
    data = {
        dialog = "MEMORIAL",
        sprite = defaultMemorialTexture,
        spacing = 16
    }
}

function everestMemorial.texture(room, entity)
    return entity.sprite or defaultMemorialTexture
end

return {
    memorial,
    everestMemorial
}