local xnaColors = require("xna_colors")
local lightBlue = xnaColors.LightBlue

local water = {}

water.name = "water"
water.fillColor = {lightBlue[1] * 0.3, lightBlue[2] * 0.3, lightBlue[3] * 0.3, 0.6}
water.borderColor = {lightBlue[1] * 0.8, lightBlue[2] * 0.8, lightBlue[3] * 0.8, 0.8}
water.placements = {
    name = "water",
    data = {
        hasBottom = false,
        width = 8,
        height = 8
    }
}

water.depth = 0

return water