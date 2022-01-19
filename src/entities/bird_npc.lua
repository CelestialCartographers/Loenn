local enums = require("consts.celeste_enums")

local birdNpc = {}

birdNpc.name = "bird"
birdNpc.depth = -1000000
birdNpc.nodeLineRenderType = "line"
birdNpc.justification = {0.5, 1.0}
birdNpc.texture = "characters/bird/crow00"
birdNpc.nodeLimits = {0, -1}
birdNpc.fieldInformation = {
    mode = {
        options = enums.bird_npc_modes,
        editable = false
    }
}
birdNpc.placements = {
    name = "bird",
    data = {
        mode = "Sleeping",
        onlyOnce = false,
        onlyIfPlayerLeft = false
    }
}

local modeFacingScale = {
    climbingtutorial = -1,
    dashingtutorial = 1,
    dreamjumptutorial = 1,
    superwalljumptutorial = -1,
    hyperjumptutorial = -1,
    movetonodes = -1,
    waitforlightningoff = -1,
    flyaway = -1,
    sleeping = 1,
    none = -1
}

function birdNpc.scale(room, entity)
    local mode = string.lower(entity.mode or "sleeping")

    return modeFacingScale[mode] or -1, 1
end

return birdNpc