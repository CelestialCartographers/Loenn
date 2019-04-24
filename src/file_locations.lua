local filesystem = require("filesystem")
local config = require("config")

local fileLocations = {}

local loennUpper = "Loenn"
local loennLower = "loenn"

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return filesystem.joinpath(os.getenv("LocalAppData"), loennUpper)

    elseif userOS == "Linux" then
        -- TODO - Is this good enough? Better alternative?
        return filesystem.joinpath(os.getenv("HOME"), "." .. loennLower)

    elseif userOS == "OS X" then
        -- TODO

    elseif userOS == "Android" then
        -- TODO

    elseif userOS == "iOS" then
        -- TODO
    end
end

function fileLocations.getSettingsPath()
    return filesystem.joinpath(fileLocations.getStorageDir(), "settings.conf")
end

function fileLocations.getCelesteDir()
    return config.readConfig(fileLocations.getSettingsPath()).celeste_dir
end

return fileLocations