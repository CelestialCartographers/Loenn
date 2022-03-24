-- Used to keep menubar reasonable
-- stylegroundWindow is updated by the styleground window, allows hotswaping

local loadedState = require("loaded_state")

local stylegroundEditor = {}

stylegroundEditor.stylegroundWindow = nil

-- TODO - Toast about map not loaded etc
function stylegroundEditor.editStylegrounds(element)
    local map = loadedState.map

    if stylegroundEditor.stylegroundWindow then
        stylegroundEditor.stylegroundWindow.editStylegrounds(map)
    end
end

return stylegroundEditor