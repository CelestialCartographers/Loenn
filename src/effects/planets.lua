local celesteEnums = require("consts.celeste_enums")

local planets = {}

planets.name = "planets"
planets.fieldInformation = {
    size = {
        options = celesteEnums.planet_effect_sizes,
        editable = false
    },
    count = {
        fieldType = "integer"
    },
    color = {
        fieldType = "color",
        allowEmpty = true
    }
}
planets.defaultData = {
    count = 32,
    size = "small",
    color = "",
    scrollx = 1.0,
    scrolly = 1.0
}

return planets