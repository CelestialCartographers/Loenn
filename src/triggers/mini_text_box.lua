local enums = require("consts.celeste_enums")

local miniTextBox = {}

miniTextBox.name = "minitextboxTrigger"
miniTextBox.fieldInformation = {
    death_count = {
        fieldType = "integer",
    },
    mode = {
        options = enums.mini_textbox_trigger_modes,
        editable = false
    }
}
miniTextBox.placements = {
    name = "mini_text_box",
    data = {
        dialog_id = "",
        mode = "OnPlayerEnter",
        only_once = true,
        death_count = -1
    }
}

return miniTextBox