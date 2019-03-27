local configs = require("configs")
local hotkeyConfig = configs.hotkeys

local hotkeyStruct = require("structs/hotkey")

-- Order dependent, takes first matching regardless of "extra" modifiers
local rawHotkeys = {
    {configs.redo, (-> print("REDO")), "Redo last action"},
    {configs.undo, (-> print("UNDO")), "Undo last action"},
}

local hotkeys = {}

for i, data <- rawHotkeys do
    local activation, callback, description = unpack(data)

    table.insert(hotkeys, hotkeyStruct.createHotkey(activation, callback))
end

return hotkeys

