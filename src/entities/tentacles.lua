local tentacles = {}

local fearDistanceOptions = {
    None = "",
    Close = "close",
    Medium = "medium",
    Far = "far"
}

tentacles.name = "tentacles"
tentacles.depth = 0
tentacles.texture = "@Internal@/tentacles"
tentacles.nodeLineRenderType = "line"
tentacles.nodeLimits = {1, -1}
tentacles.fieldInformation = {
    slide_until = {
        fieldType = "integer",
    },
    fear_distance = {
        options = fearDistanceOptions,
        editable = false
    }
}
tentacles.placements = {
    name = "tentacles",
    data = {
        fear_distance = "",
        slide_until = 0
    }
}


return tentacles