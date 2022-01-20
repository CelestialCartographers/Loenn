local enums = require("consts.celeste_enums")

local dreamingModes = {
    {"Automatic", nil},
    {"Dreaming", true},
    {"Awake", false}
}

local inventories = {
    {"Automatic", nil}
}

local coreModes = {
    {"Automatic", nil}
}

for _, inventory in ipairs(enums.inventories) do
    table.insert(inventories, {inventory, inventory})
end

for _, mode in ipairs(enums.core_modes) do
    table.insert(coreModes, {mode, mode})
end

local checkpoint = {}

checkpoint.name = "checkpoint"
checkpoint.depth = 9990
checkpoint.justification = {0.5, 1.0}
checkpoint.nodeLineRenderType = "line"
checkpoint.nodeLimits = {0, 1}
checkpoint.fieldInformation = {
    dreaming = {
        fieldType = "anything",
        options = dreamingModes,
        editable = false
    },
    inventory = {
        fieldType = "anything",
        options = inventories,
        editable = false
    },
    coreMode = {
        fieldType = "anything",
        options = coreModes,
        editable = false
    }
}

function checkpoint.texture(room, entity)
    local bg = entity.bg

    if not bg or bg == "" then
        return "objects/checkpoint/flash03"
    end

    return string.format("objects/checkpoint/bg/%s", bg)
end

return checkpoint