local enums = require("consts.celeste_enums")

local everestCoreMode = {}

everestCoreMode.name = "everest/coreModeTrigger"
everestCoreMode.associatedMods = {"Everest"}
everestCoreMode.fieldInformation = {
    mode = {
        options = enums.core_modes,
        editable = false,
    }
}
everestCoreMode.placements = {
    name = "core_mode",
    data = {
        mode = "None",
        playEffects = true
    }
}

return everestCoreMode