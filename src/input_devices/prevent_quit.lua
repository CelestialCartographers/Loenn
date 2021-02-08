local history = require("history")
local sceneHandler = require("scene_handler")

local device = {}

-- Returning true prevents program from exiting
function device:quit()
    if history.madeChanges then
        sceneHandler.sendEvent("editorQuitWithChanges")

        return true
    end

    return false
end

return device