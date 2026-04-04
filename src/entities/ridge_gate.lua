local ridgeGate = {}

ridgeGate.name = "ridgeGate"
ridgeGate.depth = 0
ridgeGate.nodeLineRenderType = "line"
ridgeGate.nodeLimits = {0, 1}
ridgeGate.justification = {0.0, 0.0}
ridgeGate.placements = {
    name = "ridge_gate",
    data = {
        texture = "objects/ridgeGate",
        strawberries = "",
        keys = "",
        width = 32,
        height = 32
    }
}

local defaultTexture = "objects/ridgeGate"

function ridgeGate.texture(room, entity)
    local texture = entity.texture or defaultTexture

    return texture
end

return ridgeGate