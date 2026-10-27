local enums = require("consts.celeste_enums")

local everestTeleport = {}

everestTeleport.name = "everest/teleport"
everestTeleport.category = "general"
everestTeleport.associatedMods = {"Everest"}
everestTeleport.fieldInformation = {
    introType = {
        options = enums.intro_types,
        editable = false
    }
}
everestTeleport.placements = {
    name = "teleport_trigger",
    data = {
        nextLevel = "",
        introType = "None",
        nearestSpawnX = 0,
        nearestSpawnY = 0,
        useDefaultSpawn = false,
        onlyOnce = false,
        flag = "",
    }
}

return everestTeleport