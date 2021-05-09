local glassBlock = {}

glassBlock.name = "glassBlock"
glassBlock.fillColor = {1.0, 1.0, 1.0, 0.6}
glassBlock.borderColor = {1.0, 1.0, 1.0, 0.8}
glassBlock.placements = {
    name = "glass_block",
    data = {
        sinks = false,
        width = 8,
        height = 8
    }
}

glassBlock.depth = 0

return glassBlock