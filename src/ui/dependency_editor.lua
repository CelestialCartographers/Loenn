-- Used to keep menubar reasonable
-- dependencyWindow is updated by the dependency window, allows hotswaping

local loadedState = require("loaded_state")

local dependencyEditor = {}

dependencyEditor.dependencyWindow = nil

-- TODO - Toast about map not loaded etc
function dependencyEditor.editDependencies(element)
    local filename = loadedState.filename
    local side = loadedState.side

    if dependencyEditor.dependencyWindow then
        dependencyEditor.dependencyWindow.editDependencies(filename, side)
    end
end

return dependencyEditor