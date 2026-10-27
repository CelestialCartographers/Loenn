local enums = require("consts.celeste_enums")

local invisibleBarrier = {}

invisibleBarrier.name = "invisibleBarrier"
invisibleBarrier.fillColor = {0.4, 0.4, 0.4, 0.8}
invisibleBarrier.borderColor = {0.0, 0.0, 0.0, 0.0}
invisibleBarrier.fieldInformation = {
    surfaceIndex = {
        options = enums.tileset_sound_ids,
        fieldType = "integer"
    }
}
invisibleBarrier.placements = {
    name = "invisible_barrier",
    data = {
        width = 8,
        height = 8,
        allowClimbing = false,
        surfaceIndex = 33,
        allowStaticMovers = true,
    }
}

return invisibleBarrier