-- TODO Editing options: mode

local everestFlag = {}

everestFlag.name = "everest/flagTrigger"
everestFlag.fieldInformation = {
    death_count = {
        fieldType = "integer",
    }
}
everestFlag.placements = {
    name = "flag",
    data = {
        flag = "",
        state = false,
        mode = "OnPlayerEnter",
        only_once = false,
        death_count = -1
    }
}

return everestFlag