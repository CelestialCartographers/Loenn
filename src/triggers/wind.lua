local enums = require("consts.celeste_enums")

local wind = {}

wind.name = "windTrigger"
wind.fieldInformation = {
    pattern = {
        options = enums.wind_patterns,
        editable = false
    }
}
wind.placements = {
    name = "wind",
    data = {
        pattern = "None"
    }
}

return wind