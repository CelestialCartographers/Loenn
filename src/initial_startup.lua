local config = require("config")
local fileLocations = require("file_locations")
local utils = require("utils")

local settingsPath = fileLocations.getSettingsDir()

local startup = {}

function startup.requiresInit()
    -- TODO - Check if the path also makes sense, IE able to find required assets 
    local data = config.readConfig(settingsPath)

    return (data and data.celeste_dir) == nil
end

function startup.findCelesteDirectory()
    local found = true
    local path = "InsertCelesteDirHere :)"

    return found, path
end

function startup.init()
    if startup.requiresInit() then
        local found, celesteDir = startup.findCelesteDirectory()
        
        if found then
            local conf = config.readConfig(settingsPath) or {}
            conf.celeste_dir = celesteDir

            config.writeConfig(settingsPath, conf)
        end

        return found
    end

    return true
end

return startup