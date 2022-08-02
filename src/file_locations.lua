local filesystem = require("utils.filesystem")
local config = require("utils.config")
local utils = require("utils")

local fileLocations = {}

local sourceDirectory = love.filesystem.getSource()

fileLocations.loennSimpleFolderName = "Loenn"
fileLocations.loennWindowsFolderName = "L" .. string.char(246) .. "nn"
fileLocations.loennLinuxFolderName = "Lönn"
fileLocations.loennZipFolderName = "L" .. string.char(148) .. "nn"

function fileLocations.getStorageDir()
    local userOS = utils.getOS()

    local simpleFolderName = fileLocations.loennSimpleFolderName
    local windowsFolderName = fileLocations.loennWindowsFolderName
    local linuxFolderName = fileLocations.loennLinuxFolderName

    if userOS == "Windows" then
        return filesystem.joinpath(os.getenv("LocalAppData"), simpleFolderName)

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

function fileLocations.getLogPath()
    return filesystem.joinpath(fileLocations.getStorageDir(), "run.log")
end

function fileLocations.getSettingsPath()
    return filesystem.joinpath(fileLocations.getStorageDir(), "settings.conf")
end

function fileLocations.getPersistencePath()
    return filesystem.joinpath(fileLocations.getStorageDir(), "persistence.conf")
end

function fileLocations.getBackupPath()
    return filesystem.joinpath(fileLocations.getStorageDir(), "Backups")
end

function fileLocations.getCelesteDir()
    return config.readConfig(fileLocations.getSettingsPath()).celesteGameDirectory
end

function fileLocations.getPluginsPath()
    return filesystem.joinpath(fileLocations.getStorageDir(), "Plugins")
end

function fileLocations.getSourcePath()
    return sourceDirectory
end

return fileLocations