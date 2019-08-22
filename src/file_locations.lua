local filesystem = require("filesystem")
local config = require("config")

local fileLocations = {}

local loennWindowsFolderName = "L" .. string.char(246) .. "nn"
local loennLinuxFolderName = "Lönn"

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return filesystem.joinpath(os.getenv("LocalAppData"), loennWindowsFolderName)

    elseif userOS == "Linux" then
        local xdgConfig = os.getenv("XDG_CONFIG_HOME")
        local home = os.getenv("HOME")

        if xdgConfig then
            return filesystem.joinpath(xdgConfig, loennLinuxFolderName)

        else
            return filesystem.joinpath(home, ".config", loennLinuxFolderName)
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