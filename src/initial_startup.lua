local config = require("config")
local fileLocations = require("file_locations")
local utils = require("utils")
local filesystem = require("filesystem")

local settingsPath = fileLocations.getSettingsPath()

local startup = {}

function startup.verifyCelesteDir(path)
    -- Check for some files/directories to check if this could be a actuall Celeste install containing the files we need

    if not path then
        return false, nil
    end

    -- Get the base path for Celeste dir
    if filesystem.filename(path) == "Celeste.exe" then
        path = filesystem.dirname(path)
    end

    if filesystem.isFile(filesystem.joinpath(path, "Celeste.exe")) and filesystem.isDirectory(filesystem.joinpath(path, "Content")) then
        return true, path
    end
end

function startup.requiresInit()
    local data = config.readConfig(settingsPath)

    if data and data.celeste_dir then
        return not startup.verifyCelesteDir(data.celeste_dir)
    end

    return true
end

function startup.findSteamDirectory()
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        -- TODO - Look for custom game specific install directory?
        local registry = require("registry")

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

        for i, path <- linuxSteamDirs do
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

        if filesystem.isDirectory(celesteSteam) and startup.verifyCelesteDir(celesteSteam) then
            return true, celesteSteam
        end
    end
end

function startup.savePath(path)
    -- Get the base path for Celeste dir
    if filesystem.filename(path) == "Celeste.exe" then
        path = filesystem.dirname(path)
    end

    local conf = config.readConfig(settingsPath) or {}
    conf.celeste_dir = path

    config.writeConfig(conf)
end

return startup