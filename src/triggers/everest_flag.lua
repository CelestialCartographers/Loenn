local enums = require("consts.celeste_enums")

local everestFlag = {}

everestFlag.name = "everest/flagTrigger"
everestFlag.associatedMods = {"Everest"}
everestFlag.fieldInformation = {
    death_count = {
        fieldType = "integer",
    },
    mode = {
        options = enums.everest_flag_trigger_modes,
        editable = false
    }
}
everestFlag.placements = {
    name = "flag",
    data = {
        flag = "",
        state = true,
        mode = "OnPlayerEnter",
        only_once = false,
        death_count = -1
    }
}

return everestFlag