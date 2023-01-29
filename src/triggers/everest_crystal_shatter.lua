local enums = require("consts.celeste_enums")

local everestCrystalShatter = {}

everestCrystalShatter.name = "everest/crystalShatterTrigger"
everestCrystalShatter.associatedMods = {"Everest"}
everestCrystalShatter.fieldInformation = {
    mode = {
        options = enums.everest_crystal_shatter_trigger_modes,
        editable = false
    }
}
everestCrystalShatter.placements = {
    name = "crystal_shatter",
    data = {
        mode = "All"
    }
}

return everestCrystalShatter