local cassette = {}

cassette.name = "cassette"
cassette.depth = -1000000
cassette.nodeLineRenderType = "line"
cassette.texture = "collectables/cassette/idle00"

cassette.placements = {
    name = "cassette"
}

function cassette.nodeLimits(room, entity)
    return 2, 2
end

return cassette