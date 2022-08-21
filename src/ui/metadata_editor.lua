-- Used to keep menubar reasonable
-- metadataWindow is updated by the metadata window, allows hotswaping

local loadedState = require("loaded_state")

local metadataEditor = {}

metadataEditor.metadataWindow = nil

-- TODO - Toast about map not loaded etc
function metadataEditor.editMetadata(element)
    local side = loadedState.side

    if metadataEditor.metadataWindow then
        metadataEditor.metadataWindow.editMetadata(side)
    end
end

return metadataEditor