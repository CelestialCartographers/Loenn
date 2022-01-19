local enums = require("consts.celeste_enums")

local spawnFacing = {}

spawnFacing.name = "spawnFacingTrigger"
spawnFacing.fieldInformation = {
    facing = {
        options = enums.spawn_facing_trigger_facings,
        editable = false
    }
}
spawnFacing.placements = {
    name = "spawn_facing",
    data = {
        facing = "Right"
    }
}

return spawnFacing