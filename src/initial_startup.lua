local config = require("utils.config")
local fileLocations = require("file_locations")
local utils = require("utils")
local filesystem = require("utils.filesystem")

local settingsPath = fileLocations.getSettingsPath()

local startup = {}

function startup.cleanupPath(path)
    if not path then
        return false
    end

    local filename = filesystem.filename(path)
    local macOS = love.system.getOS() == "OS X"

    -- Get the base path for Celeste dir
    if filename == "Celeste.exe" then
        path = filesystem.dirname(path)
    end

    if macOS and filename == "Celeste.app" then
        path = filesystem.joinpath(path, "Contents", "MacOS")
    end

    return path
end

function startup.cleanupDirPath(path)
    if not path then
        return false
    end

    local macOS = love.system.getOS() == "OS X"

    if macOS and filesystem.filename(path) == "Celeste.app" then
        return startup.cleanupPath(path)
    elseif macOS and filesystem.isFile(filesystem.joinpath(path, "Celeste.app")) then
        return startup.cleanupDirPath(filesystem.joinpath(path, "Contents", "MacOS"))
    elseif filesystem.isFile(filesystem.joinpath(path, "Celeste.exe")) then
        return path
    else
        return false
    end
end

function startup.verifyCelesteDir(path)
    -- Check for some files/directories to check if this could be a actuall Celeste install containing the files we need

    if not path then
        return false
    end

    if filesystem.isFile(filesystem.joinpath(path, "Celeste.exe")) and filesystem.isDirectory(filesystem.joinpath(path, "Content")) then
        return true
    end

    return false
end

function startup.requiresInit()
    local data = config.readConfig(settingsPath)

    if data and data.celesteGameDirectory then
        return not startup.verifyCelesteDir(data.celesteGameDirectory)
    end

    return true
end

function startup.findSteamDirectory()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        -- TODO - Look for custom game specific install directory?
        local registry = require("utils.windows_registry")

        local steam64Bits = registry.getKey("HKLM\\SOFTWARE\\WOW6432Node\\Valve\\Steam")
        local steam32Bits = registry.getKey("HKLM\\SOFTWARE\\Valve\\Steam")
        local steamDir = steam64Bits and steam64Bits.InstallPath or steam32Bits and steam32Bits.InstallPath

        return steamDir

    elseif userOS == "OS X" then
        return filesystem.joinpath(os.getenv("HOME"), "Library", "Application Support", "Steam")

    elseif userOS == "Linux" then
        local linuxSteamDirs = {
            filesystem.joinpath(os.getenv("HOME"), ".local", "share", "Steam"),
            filesystem.joinpath(os.getenv("HOME"), ".steam", "steam"),
        }

        for _, path in ipairs(linuxSteamDirs) do
            if filesystem.isDirectory(path) then
                return path
            end
        end

        return false
    end
end

function startup.findCelesteDirectory()
    local steam = startup.findSteamDirectory()

    if steam then
        local celesteSteam = filesystem.joinpath(steam, "steamapps", "common", "Celeste")
        local cleanedPath = startup.cleanupPath(celesteSteam)

        if cleanedPath and filesystem.isDirectory(celesteSteam) then
            return true, celesteSteam
        end
    end

    return false, ""
end

function startup.savePath(path)
    path = startup.cleanupPath(path)

    local conf = config.readConfig(settingsPath) or {}
    conf.celesteGameDirectory = path

    config.writeConfig(conf)
end

return startup