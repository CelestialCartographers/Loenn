-- Used to keep menubar reasonable
-- settingsWindow is updated by the metadata window, allows hotswaping

local loadedState = require("loaded_state")

local settingsEditor = {}

settingsEditor.settingsWindow = nil

function settingsEditor.editSettings(element)
    if settingsEditor.settingsWindow then
        settingsEditor.settingsWindow.editSettings()
    end
end

return settingsEditor
