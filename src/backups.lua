local configs = require("configs")
local loadedState = require("loaded_state")
local fileLocations = require("file_locations")
local utils = require("utils")
local logging = require("logging")
local lfs = require("lib.lfs_ffi")
local history = require("history")

local backups = {}

backups.lastBackup = 0

local timestampFormat = "%Y-%m-%d %H-%M-%S"
local timestampPattern = "(%d%d%d%d)-(%d%d)-(%d%d) (%d%d)-(%d%d)-(%d%d)"

local function saveCallback(filename)
    logging.debug(string.format("Created map backup to '%s'", filename))
end

function backups.getBackupMapName(side)
    side = side or loadedState.side

    if side then
        local map = side.map
        local mapName = map.package
        local hasPackageName = mapName and #mapName > 0

        if not hasPackageName then
            if loadedState.filename then
                mapName = utils.filename(utils.stripExtension(loadedState.filename))

            else
                mapName = "Unsaved"
            end
        end

        return mapName
    end
end

-- Folder to put the backup in
function backups.getBackupPath(side)
    local backupsPath = fileLocations.getBackupPath()
    local mapName = backups.getBackupMapName(side)

    if mapName then
        return utils.joinpath(backupsPath, mapName)
    end
end

local function findOldestBackup(fileInformations)
    local oldestTimestamp = math.huge
    local oldestFilename

    for filename, info in pairs(fileInformations) do
        if info.created < oldestTimestamp then
            oldestTimestamp = info.created
            oldestFilename = filename
        end
    end

    return oldestFilename
end

-- TODO - Implement more modes, fallback to "oldest" for now
local function findBackupToPrune(fileInformations)
    local pruningMode = configs.backups.backupMode

    return findOldestBackup(fileInformations)
end

local function getTimeFromFilename(filename)
    local year, month, day, hour, minute, second = string.match(filename, timestampPattern)

    return os.time({year=year, month=month, day=day, hour=hour, min=minute, sec=second})
end

function backups.cleanupBackups(side)
    local backupFilenames = backups.getMapBackups(side)
    local backupCount = #backupFilenames
    local maximumBackups = configs.backups.maximumFiles

    if backupCount > maximumBackups then
        local fileInformations = {}

        for _, filename in ipairs(backupFilenames) do
            fileInformations[filename] = {
                filename = filename,
                created = getTimeFromFilename(filename)
            }
        end

        while backupCount > maximumBackups do
            local deleteFilename = findBackupToPrune(fileInformations)

            if not deleteFilename then
                break
            end

            local success = utils.remove(deleteFilename)

            if not success then
                break
            end

            fileInformations[deleteFilename] = nil
            backupCount -= 1
        end
    end
end

function backups.getMapBackups(side)
    local filenames = {}
    local backupPath = backups.getBackupPath(side)

    if backupPath then
        -- utils.getFilenames only works on mounted paths
        for filename in lfs.dir(backupPath) do
            -- Make sure the filename has the expected format
            if utils.fileExtension(filename) == "bin" then
                if string.match(filename, timestampPattern) then
                    local fullPath = utils.joinpath(backupPath, filename)

                    table.insert(filenames, fullPath)
                end
            end
        end
    end

    return filenames
end

function backups.createBackup(side, lastChange)
    local backupPath = backups.getBackupPath(side)

    if backupPath then
        local timestamp = os.date(timestampFormat, os.time())
        local filename = utils.joinpath(backupPath, timestamp .. ".bin")

        backups.lastBackup = os.time()

        loadedState.saveFile(filename, saveCallback)
        backups.cleanupBackups(side)
    end
end

function backups.createBackupDevice()
    local device = {
        _type = "device",
        _enabled = true
    }

    device.deltaTimeAcc = 0
    device.backupRate = configs.backups.backupRate

    -- Always keep the device running, but skip the backup step if backups are disabled
    -- Prevent hammering the config for values, update every time we would make a backup
    function device.update(dt)
        device.deltaTimeAcc += dt

        if device.deltaTimeAcc >= device.backupRate then
            device.deltaTimeAcc -= device.backupRate
            device.backupRate = configs.backups.backupRate

            if configs.backups.enabled then
                if history.lastChange > backups.lastBackup then
                    backups.createBackup(loadedState.side, history.lastChange)
                end
            end
        end
    end

    return device
end

return backups