local checkpoint = {}

checkpoint.name = "checkpoint"
checkpoint.depth = 9990
checkpoint.justification = {0.5, 1.0}
checkpoint.nodeLineRenderType = "line"
checkpoint.nodeLimits = {0, 1}

function checkpoint.texture(room, entity)
    local bg = entity.bg

    if not bg or bg == "" then
        return "objects/checkpoint/flash03"
    end

    return string.format("objects/checkpoint/bg/%s", bg)
end

return checkpoint