local water = {}

water.name = "water"
water.fillColor = {0.0, 0.0, 1.0, 0.4}
water.borderColor = {0.0, 0.0, 1.0, 1.0}
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