local config = require("config")
local fileLocations = require("file_locations")
local utils = require("utils")
local filesystem = require("filesystem")

local settingsPath = fileLocations.getSettingsPath()

local startup = {}

function startup.verifyCelesteDir(path)
    -- Check for some files/directories to check if this could be a actuall Celeste install containing the files we need

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
        --TODO - Registry magic
        return "Get Cruor to implement the registry stuff :)"

    elseif userOS == "OS X" then
        return filesystem.joinpath(os.getenv("HOME"), "Library", "Application Support", "Steam")

    elseif userOS == "Linux" then
        return filesystem.joinpath(os.getenv("HOME"), ".local", "share", "Steam")
    end
end

function startup.findCelesteDirectory()
    local steam = startup.findSteamDirectory()

    if steam then
        local celesteSteam = filesystem.joinpath(steam, "steamapps", "common", "Celeste")

        if filesystem.isDirectory(celesteSteam) then
            return true, celesteSteam
        end
    end

    -- Couldn't auto detect, select manually
    while true do
        local selected = filesystem.openDialog()

        if selected then
            local valid, fixed = startup.verifyCelesteDir(selected) 

            if valid then
                return true, fixed
            end
        end

        -- TODO - Notify user about this being correct or not
    end
end

function startup.init()
    if startup.requiresInit() then
        local found, celesteDir = startup.findCelesteDirectory()
        
        if found then
            local conf = config.readConfig(settingsPath) or {}
            conf.celeste_dir = celesteDir

            config.writeConfig(conf)
        end

        return found
    end

    return true
end

return startup