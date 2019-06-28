local filesystem = require("filesystem")
local config = require("config")

local fileLocations = {}

-- TODO - Test if Windows approves of Lönn instead of Loenn
local loennUpper = "Loenn"
local loennLower = "lönn"

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return filesystem.joinpath(os.getenv("LocalAppData"), loennUpper)

    elseif userOS == "Linux" then
        local xdgConfig = os.getenv("XDG_CONFIG_HOME")
        local home = os.getenv("HOME")

        if xdgConfig then
            return filesystem.joinpath(xdgConfig, loennLower)

        else
            return filesystem.joinpath(home, ".config", loennLower)
        end

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