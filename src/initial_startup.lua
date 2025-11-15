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
    if filesystem.isFile(path) then
        path = filesystem.dirname(path)
    end

    if macOS then
        if filename == "Celeste" then
            local pathApp = filesystem.joinpath(path, "Celeste.app")

            if filesystem.isDirectory(pathApp) then
                filename = "Celeste.app"
                path = pathApp
            end
        end

        if filename == "Celeste.app" then
            local pathResources = filesystem.joinpath(path, "Contents", "Resources")
            local pathMacOS = filesystem.joinpath(path, "Contents", "MacOS")

            if filesystem.isDirectory(pathResources) then
                path = pathResources

            else
                path = pathMacOS
            end
        end
    end

    -- Check for Everest orig folder, we want the base game directory
    local oneFolderUp = filesystem.dirname(path)
    local inOrigFolder = filesystem.isDirectory(filesystem.joinpath(oneFolderUp, "orig"))

    if inOrigFolder then
        path = oneFolderUp
    end

    return path
end

function startup.verifyCelesteDir(path)
    -- Check for some files/directories to check if this could be a actuall Celeste install containing the files we need

    if not path then
        return false
    end

    local hasCelesteExe = filesystem.isFile(filesystem.joinpath(path, "Celeste.exe"))
    local hasCelesteDll = filesystem.isFile(filesystem.joinpath(path, "Celeste.dll"))
    local hasGameplayMeta = filesystem.isFile(filesystem.joinpath(path, "Content", "Graphics", "Atlases", "Gameplay.meta"))

    if (hasCelesteExe or hasCelesteDll) and hasGameplayMeta then
        return true
    end

    return false
end

function startup.requiresInit()
    local data = config.readConfig(settingsPath)

    if data and data.celesteGameDirectory then
        local verified = startup.verifyCelesteDir(data.celesteGameDirectory)

        -- Attempt to save changes if path is valid
        -- Fixes issue with Everest orig folder
        if verified then
            startup.savePath(data.celesteGameDirectory, data)
        end

        return not verified
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

function startup.savePath(path, conf)
    path = startup.cleanupPath(path)
    conf = conf or config.readConfig(settingsPath) or {}

    local current = conf.celesteGameDirectory

    if not current or path ~= current then
        conf.celesteGameDirectory = path

        config.writeConfig(conf)
    end
end

return startup