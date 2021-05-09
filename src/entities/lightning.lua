local lightning = {}

lightning.name = "lightning"
lightning.depth = -1000100
lightning.fillColor = {0.55, 0.97, 0.96, 0.4}
lightning.borderColor = {0.99, 0.96, 0.47, 1.0}
lightning.nodeLineRenderType = "line"
lightning.nodeLimits = {0, 1}
lightning.placements = {
    name = "lightning",
    data = {
        width = 8,
        height = 8,
        perLevel = false,
        moveTime = 5.0
    }
}

return lightning