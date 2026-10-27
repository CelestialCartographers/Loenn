local fileLocations = require("file_locations")
local utils = require("utils")
local configs = require("configs")
local sceneHandler = require("scene_handler")

local sanitizer = {}

function sanitizer.beforeSave(filename)
    if configs.editor.warnOnVanillaMaps then
        local vanillaMapsFolder = utils.joinpath(fileLocations.getCelesteDir(), "Content", "Maps")

        if utils.startsWith(filename, vanillaMapsFolder) then
            sceneHandler.sendEvent("saveSanitizerVanillaMapWarning")

            return false
        end
    end
end

return sanitizer