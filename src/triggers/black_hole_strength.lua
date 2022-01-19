local enums = require("consts.celeste_enums")

local blackHoleStrength = {}

blackHoleStrength.name = "blackholeStrength"
blackHoleStrength.fieldInformation = {
    strength = {
        options = enums.black_hole_trigger_strengths,
        editable = false
    }
}
blackHoleStrength.placements = {
    name = "black_hole_strength",
    data = {
        strength = "Mild"
    }
}

return blackHoleStrength