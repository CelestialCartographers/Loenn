local cliffsideFlag = {}

cliffsideFlag.name = "cliffside_flag"
cliffsideFlag.depth = 8999
cliffsideFlag.justification = {0.0, 0.0}
cliffsideFlag.fieldInformation = {
    index = {
        fieldType = "integer",
    }
}
cliffsideFlag.placements = {
    name = "cliffside_flag",
    data = {
        index = 0
    }
}

function cliffsideFlag.texture(room, entity)
    local index = entity.index or 0

    return string.format("scenery/cliffside/flag%02d", index)
end

return cliffsideFlag