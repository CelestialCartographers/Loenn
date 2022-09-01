local celesteEnums = require("consts.celeste_enums")

local tentacles = {}

tentacles.name = "tentacles"
tentacles.fieldInformation = {
    color = {
        fieldType = "color",
        allowEmpty = true
    },
    side = {
        options = celesteEnums.tentacle_effect_directions,
        editable = false
    }
}
tentacles.defaultData = {
    color = "",
    side = "Right",
    offset = 0.0
}

return tentacles