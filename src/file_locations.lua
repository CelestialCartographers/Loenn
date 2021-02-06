local filesystem = require("filesystem")
local config = require("config")

local fileLocations = {}

fileLocations.loennSimpleFolderName = "Loenn"
fileLocations.loennWindowsFolderName = "L" .. string.char(246) .. "nn"
fileLocations.loennLinuxFolderName = "Lönn"
fileLocations.loennZipFolderName = "L" .. string.char(148) .. "nn"

function fileLocations.getStorageDir()
    local userOS = love.system.getOS()

    local windowsFolderName = fileLocations.loennWindowsFolderName
    local linuxFolderName = fileLocations.loennLinuxFolderName

    if userOS == "Windows" then
        return filesystem.joinpath(os.getenv("LocalAppData"), windowsFolderName)

    elseif userOS == "Linux" then
        local xdgConfig = os.getenv("XDG_CONFIG_HOME")
        local home = os.getenv("HOME")

        if xdgConfig then
            return filesystem.joinpath(xdgConfig, linuxFolderName)

        else
            return filesystem.joinpath(home, ".config", linuxFolderName)
        end

    elseif userOS == "OS X" then
        local home = os.getenv("HOME")

        return filesystem.joinpath(home, "Library", "Application Support", linuxFolderName)

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
    return config.readConfig(fileLocations.getSettingsPath()).celesteGameDirectory
end

return fileLocations