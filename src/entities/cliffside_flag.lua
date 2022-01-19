local cliffsideFlag = {}

cliffsideFlag.name = "cliffside_flag"
cliffsideFlag.depth = 8999
cliffsideFlag.justification = {0.0, 0.0}
cliffsideFlag.fieldInformation = {
    index = {
        fieldType = "integer",
        options = {
            0, 1, 2, 3,
            4, 5, 6, 7,
            8, 9, 10
        },
        editable = false
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