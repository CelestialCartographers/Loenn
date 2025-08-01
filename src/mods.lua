local utils = require("utils")
local fileLocations = require("file_locations")
local yaml = require("lib.yaml")
local config = require("utils.config")
local configs = require("configs")
local filesystem = require("utils.filesystem")
local logging = require("logging")

local modHandler = {}

local everestBuildNumberMatch = "EverestBuild(%d*)"

modHandler.internalModContent = "@Internal@"
modHandler.commonModContent = "@ModsCommon@"
modHandler.everestYamlFilenames = {
    "everest.yaml",
    "everest.yml"
}
modHandler.specificModContentSymbol = "$"
modHandler.specificModContent = "$%s$"
modHandler.pluginFolderNames = {
    fileLocations.loennSimpleFolderName
}

modHandler.loadedMods = {}
modHandler.loadedNameLookup = {}
modHandler.knownPluginRequires = {}
modHandler.modMetadata = {}
modHandler.modSettings = {}
modHandler.modPersistence = {}

modHandler.modNamesFormat = "[%s]"
modHandler.modNamesSeparator = " + "

modHandler.persistenceBufferTime = 300

modHandler.cacheableFiletypes = {
    zip = {
        png = true,
        lang = true,
        lua = true
    },
    folder = {
        png = true
    }
}

function modHandler.getModFilenames(modFolderName, path, filenames, predicate, useCache)
    filenames = filenames or {}

    local modFilenames = {}

    if useCache then
        modFilenames = modHandler.getOrCacheFilenames(modFolderName)

    else
        modFilenames = utils.getFilenames(path, true, {}, nil, true)
    end

    for _, filename in ipairs(modFilenames) do
        if utils.startsWith(filename, path) then
            if predicate then
                if predicate(filename) then
                    table.insert(filenames, filename)
                end

            else
                table.insert(filenames, filename)
            end
        end
    end

    return filenames
end

-- Finds files in all folders that are recognized as plugin folders
function modHandler.findPluginFiletype(startFolder, filetype)
    local filenames = {}

    for _, folderName in ipairs(modHandler.pluginFolderNames) do
        for modFolderName, _ in pairs(modHandler.loadedMods) do
            local pluginStartFolder = utils.convertToUnixPath(utils.joinpath(
                folderName,
                startFolder
            ))

            modHandler.findModFolderFiletype(modFolderName, filenames, pluginStartFolder, filetype)
        end
    end

    return filenames
end

function modHandler.canCacheFiletype(modFolderName, filetype)
    if not filetype then
        return false
    end

    local modInfo = modHandler.loadedMods[modFolderName]

    if not modInfo then
        return false
    end

    local isZip = modInfo.zipFile
    local cacheKey = isZip and "zip" or "folder"

    return modHandler.cacheableFiletypes[cacheKey][filetype] or false
end

-- Fine tuned search for exactly one mod folder
function modHandler.findModFolderFiletype(modFolderName, filenames, startFolder, filetype)
    local path = utils.convertToUnixPath(utils.joinpath(
        string.format(modHandler.specificModContent, modFolderName),
        startFolder
    ))

    if filetype then
        local filetypePredicate = function(filename)
            return utils.fileExtension(filename) == filetype
        end

        local canCache = modHandler.canCacheFiletype(modFolderName, filetype)

        return modHandler.getModFilenames(modFolderName, path, filenames, filetypePredicate, canCache)

    else
        return modHandler.getModFilenames(modFolderName, path, filenames)
    end
end

-- Finds files relative to the root of every loaded mod
-- This is more performant than using the common mount point when looking for files recursively
function modHandler.findModFiletype(startFolder, filetype, folderNames)
    -- Fall back to all loaded mods
    folderNames = folderNames and table.flip(folderNames) or modHandler.loadedMods

    local filenames = {}

    for modFolderName, _ in pairs(folderNames) do
        modHandler.findModFolderFiletype(modFolderName, filenames, startFolder, filetype)
    end

    return filenames
end

function modHandler.findPlugins(pluginType)
    return modHandler.findPluginFiletype(pluginType, "lua")
end

function modHandler.findLanguageFiles(startPath)
    startPath = startPath or "lang"

    return modHandler.findPluginFiletype(startPath, "lang")
end

function modHandler.mountable(path)
    local attributes = utils.pathAttributes(path)

    if attributes and attributes.mode == "directory" then
        return true, "folder"

    elseif utils.fileExtension(path) == "zip" then
        return true, "zip"
    end

    return false
end

function modHandler.getFilenameModName(filename)
    if not filename then
        return
    end

    local celesteDir = fileLocations.getCelesteDir()
    local celesteModsDir = utils.joinpath(celesteDir, "Mods")
    local celesteParts = utils.splitpath(utils.convertToUnixPath(celesteModsDir), "/")
    local filenameParts = utils.splitpath(utils.convertToUnixPath(filename), "/")

    -- Remove empty parts from end of celesteParts
    for i = #celesteParts, 1, -1 do
        if celesteParts[i] == "" then
            celesteParts[i] = nil

        else
            break
        end
    end

    for i, part in ipairs(celesteParts) do
        if filenameParts[i] ~= part then
            return
        end
    end

    -- Make sure this is a folder and not a map file directly in mods folder
    if not filenameParts[#celesteParts + 2] then
        return
    end

    -- Fetch part after CelesteRoot/Mods/
    return filenameParts[#celesteParts + 1]
end

function modHandler.getFilenameModPath(filename)
    local modName = modHandler.getFilenameModName(filename)
    local celesteDir = fileLocations.getCelesteDir()

    if modName then
        return utils.joinpath(celesteDir, "Mods", modName)
    end
end

-- Assumes entity names are "modName/entityName"
function modHandler.getEntityModPrefix(name)
    return name:match("^(.-)/")
end

function modHandler.findPluginLoennFolder(mountPoint)
    for _, folderName in ipairs(modHandler.pluginFolderNames) do
        local folderTestPath = mountPoint .. "/" .. folderName
        local folderInfo = love.filesystem.getInfo(folderTestPath)

        if folderInfo and folderInfo.type == "directory" then
            return mountPoint .. "/" .. folderName
        end
    end
end

local function getbuildNumber(filename)
    local fullFilename = utils.joinpath(fileLocations.getCelesteDir(), filename)
    local fh = utils.getFileHandle(fullFilename, "rb")

    if fh then
        local data = fh:read("*a")
        local buildNumber = string.match(data, everestBuildNumberMatch)

        fh:close()

        return buildNumber
    end
end

function modHandler.getEverestBuildNumber()
    -- Check both, .NET core builds of Everest has it in the .dll
    return getbuildNumber("Celeste.exe") or getbuildNumber("Celeste.dll")
end

function modHandler.getEverestVersion()
    local buildNumber = modHandler.getEverestBuildNumber()

    if buildNumber then
        return string.format("1.%s.0", buildNumber)
    end
end

function modHandler.findEverestYaml(mountPoint)
    for _, filename in ipairs(modHandler.everestYamlFilenames) do
        local yamlTestPath = mountPoint .. "/" .. filename
        local info = love.filesystem.getInfo(yamlTestPath)

        if info and info.type == "file" then
            return yamlTestPath, filename
        end
    end
end

-- Find existing or fall back to first search filename
function modHandler.findEverestYamlOrDefault(mountPoint)
    local yamlTestPath, filename = modHandler.findEverestYaml(mountPoint)

    return filename or modHandler.everestYamlFilenames[1]
end

function modHandler.updateModMetadataCache(modMetadata, folderName)
    modHandler.modMetadata[folderName] = modMetadata

    if modHandler.loadedMods[folderName] then
        modHandler.loadedMods[folderName].metadata = modMetadata
    end
end

function modHandler.readModMetadata(path, mountPoint, folderName, updateCache)
    local result = {}
    local yamlFilename = modHandler.findEverestYaml(mountPoint)

    if yamlFilename then
        local content, size = love.filesystem.read(yamlFilename)

        if content then
            local success, data = pcall(yaml.read, utils.stripByteOrderMark(content))

            if success and type(data) == "table" then
                result = data
                result._mountPointLoenn = modHandler.findPluginLoennFolder(mountPoint)
            end
        end
    end

    result._mountPoint = mountPoint
    result._path = path
    result._folderName = folderName

    if updateCache ~= false then
        modHandler.updateModMetadataCache(result, folderName)
    end

    return result
end

function modHandler.findLoadedMod(name)
    for modFolderName, metadata in pairs(modHandler.modMetadata) do
        for _, info in ipairs(metadata) do
            if info.Name == name then
                return info, metadata
            end
        end
    end
end

function modHandler.hasLoadedMod(name)
    local info, metadata = modHandler.findLoadedMod(name)

    return info ~= nil
end

-- Only works on files loaded with requireFromPlugin
function modHandler.unrequireKnownPluginRequires()
    for name, _ in pairs(modHandler.knownPluginRequires) do
        utils.unrequire(name)
    end
end

-- Defaults to current mod directory
function modHandler.requireFromPlugin(lib, modName)
    local libPrefix

    if modName then
        local modInfo, pluginInfo = modHandler.findLoadedMod(modName)

        if modInfo then
            libPrefix = pluginInfo._mountPointLoenn
        end

    else
        local info = debug.getinfo(2)
        local source = info.source
        local parts = string.split(source, "/")()

        libPrefix = table.concat(parts, ".", 1, 2)
    end

    if lib and libPrefix then
        local requireName = libPrefix .. "." .. lib
        local success, result = utils.tryrequire(requireName)

        if success then
            modHandler.knownPluginRequires[requireName] = result

            return result
        end

    else
        -- TODO - Add warning
    end
end

-- Defaults to current mod directory
function modHandler.readFromPlugin(filename, modName)
    local filenamePrefix

    if modName then
        local modInfo, pluginInfo = modHandler.findLoadedMod(modName)

        if modInfo then
            filenamePrefix = pluginInfo._mountPointLoenn
        end

    else
        local info = debug.getinfo(2)
        local source = info.source
        local parts = string.split(source, "/")()

        filenamePrefix = table.concat(parts, "/", 1, 2)
    end

    if filename and filenamePrefix then
        local content = utils.readAll(filenamePrefix .. "/" .. filename)

        return content
    end
end

local function createModSettingDirectory(modName)
    -- Exit early if the requested mod isn't loaded
    -- No need to create folders for a mod that potentially doesn't exist
    if not modHandler.hasLoadedMod(modName) then
        return false
    end

    local pluginsPath = fileLocations.getPluginsPath()
    local pluginsModPath = utils.joinpath(pluginsPath, modName)

    if not filesystem.isDirectory(pluginsModPath) then
        filesystem.mkpath(pluginsModPath)
    end

    return true
end

-- Work our way up the stack to find the first plugin related source
-- This makes sure the function can be used from anywhere
function modHandler.getCurrentModName(maxDepth)
    maxDepth = maxDepth or 10

    for i = 2, maxDepth do
        local info = debug.getinfo(i)

        if not info then
            return
        end

        local source = info.source

        if utils.startsWith(source, modHandler.specificModContentSymbol) then
            local parts = string.split(source, "/")()
            local specificName = parts[1]

            -- Match the specific name to a loaded mod's mount point
            for modFolderName, metadata in pairs(modHandler.modMetadata) do
                if metadata._mountPoint == specificName then
                    if metadata[1] then
                        return metadata[1].Name
                    end
                end
            end
        end
    end
end

-- Defaults to current mod
function modHandler.getModSettings(modName)
    modName = modName or modHandler.getCurrentModName()

    if modName then
        if not modHandler.modSettings[modName] then
            local pluginsPath = fileLocations.getPluginsPath()
            local settingsPath = utils.joinpath(pluginsPath, modName, "settings.conf")

            createModSettingDirectory(modName)

            modHandler.modSettings[modName] = config.readConfig(settingsPath)
        end

        return modHandler.modSettings[modName]
    end
end

-- Defaults to current mod
function modHandler.getModPersistence(modName)
    modName = modName or modHandler.getCurrentModName()

    if not modHandler.modPersistence[modName] then
        local pluginsPath = fileLocations.getPluginsPath()
        local persistencePath = utils.joinpath(pluginsPath, modName, "persistence.conf")

        createModSettingDirectory(modName)

        modHandler.modPersistence[modName] = config.readConfig(persistencePath, modHandler.persistenceBufferTime)
    end

    return modHandler.modPersistence[modName]
end

function modHandler.writeModPersistences()
    for _, persistence in pairs(modHandler.modPersistence) do
        config.writeConfig(persistence, true)
    end
end

function modHandler.invalidateFilenamesCacheFromPath(path)
    local modPath = modHandler.getFilenameModPath(path)

    if modPath then
        local metadata = modHandler.getModMetadataFromPath(modPath)

        if metadata then
            modHandler.invalidateFilenamesCache(metadata._folderName)
        end
    end
end

function modHandler.invalidateFilenamesCache(modFolderName)
    modHandler.getOrCacheFilenames(modFolderName, true, true)
end

function modHandler.getOrCacheFilenames(modFolderName, useYield, force)
    local storageDir = fileLocations.getStorageDir()
    local storageCacheDir = utils.joinpath(storageDir, "Cache", "ModFilenames")
    local modCacheConfig = utils.joinpath(storageCacheDir, modFolderName .. ".conf")
    local cacheConfig = config.readConfig(modCacheConfig)

    if not filesystem.isDirectory(storageCacheDir) then
        filesystem.mkpath(storageCacheDir)
    end

    local modInfo = modHandler.loadedMods[modFolderName]

    if not modInfo then
        return
    end

    local isZip = modInfo.zipFile
    local mtime = modInfo.mtime

    local updateCache = force or not cacheConfig.filenames

    -- Invalidate cache if zip file is newer than our cache
    if cacheConfig.createdAt and isZip then
        updateCache = updateCache or mtime > cacheConfig.createdAt
    end

    if updateCache then
        if configs.debug.logModFilenamesCache then
            local message = string.format("Updated filename cache for '%s'", modFolderName)

            logging.info(message)
        end

        local specificMountPoint = string.format(modHandler.specificModContent, modFolderName)
        local modFilenames = utils.getFilenames(specificMountPoint, true, {}, nil, useYield)

        cacheConfig.createdAt = mtime
        cacheConfig.filenames = modFilenames
    end

    return cacheConfig.filenames
end

function modHandler.mountMod(path, force)
    if not path then
        return false
    end

    local directory, filename = utils.dirname(path), utils.filename(path)
    local modFolderName = filename:gsub("%.", "_")
    local loaded = modHandler.loadedMods[modFolderName]

    if not loaded or force then
        if modHandler.mountable(path) then
            -- Replace "." in ".zip" to prevent require from getting confused
            local directory, filename = utils.dirname(path), utils.filename(path)
            local modFolderName = filename:gsub("%.", "_")
            local specificMountPoint = string.format(modHandler.specificModContent, modFolderName)

            -- Can't mount the same path twice, trick physfs into loading both
            love.filesystem.mountUnsandboxed(path, modHandler.commonModContent .. "/", 1)
            love.filesystem.mountUnsandboxed(utils.joinpath(directory, ".", filename), specificMountPoint, 1)

            local modMetadata = modHandler.readModMetadata(path, specificMountPoint, modFolderName)

            modHandler.getOrCacheFilenames(modFolderName, true)
            modHandler.modMetadata[modFolderName] = modMetadata
            modHandler.loadedMods[modFolderName] = {
                zipFile = filesystem.isFile(path),
                mtime = filesystem.mtime(path),
                metadata = modMetadata,
            }
        end
    end

    return not loaded
end

function modHandler.mountMods(directory, force)
    directory = directory or utils.joinpath(fileLocations.getCelesteDir(), "Mods")

    if utils.isDirectory(directory) then
        for filename, dir in utils.listDir(directory) do
            if filename ~= "." and filename ~= ".." then
                modHandler.mountMod(utils.joinpath(directory, filename), force)

                coroutine.yield()
            end
        end
    end
end

local function getModMetadataByKeyCached(value, key, hasTriedMount)
    local modFolder = modHandler.loadedNameLookup[value]

    if not modFolder then
        for modFolder, metadata in pairs(modHandler.modMetadata) do
            local metadataValue = metadata[key]

            if utils.samePath(metadataValue, value) then
                local loadedModInfo = modHandler.loadedMods[modFolder]

                if loadedModInfo then
                    modHandler.loadedNameLookup[value] = modFolder
                end

                return metadata
            end
        end
    end

    if not hasTriedMount then
        -- Try mounting the mod folder, might be a new folder since startup
        modHandler.mountMod(value)

        return getModMetadataByKeyCached(value, key, true)
    end

    return modHandler.modMetadata[modFolder]
end

local function getModMetadataFromRealFilename(filename)
    return getModMetadataByKeyCached(filename, "_path")
end

local function getModMetadataFromSpecific(filename)
    return getModMetadataByKeyCached(filename, "_mountPoint")
end

function modHandler.getModMetadataFromPath(path)
    if not path then
        return
    end

    if utils.startsWith(path, modHandler.specificModContentSymbol) then
        local parts = utils.splitpath(path, "/")
        local firstPart = parts[1]

        return getModMetadataFromSpecific(firstPart)

    elseif utils.startsWith(path, modHandler.commonModContent) then
        local realFilename = love.filesystem.getRealDirectory(path)

        if not realFilename then
            return
        end

        return getModMetadataFromRealFilename(realFilename)

    else
        -- Assume anything left over is a real filename

        return getModMetadataFromRealFilename(path)
    end
end

function modHandler.getModNamesFromMetadata(metadata)
    if metadata then
        if #metadata == 1 and metadata[1].Name then
            return {metadata[1].Name}

        else
            local names = {}

            for _, info in ipairs(metadata) do
                if info.Name then
                    table.insert(names, info.Name)
                end
            end

            return names
        end
    end
end

function modHandler.getDependencyModNames(metadata, addSelf)
    local dependedOnMods = {}

    for _, info in ipairs(metadata) do
        if addSelf ~= false and info.Name then
            table.insert(dependedOnMods, info.Name)
        end

        for _, dependency in ipairs(info.Dependencies or {}) do
            if dependency.Name then
                table.insert(dependedOnMods, dependency.Name)
            end
        end
    end

    return dependedOnMods
end

function modHandler.getAvailableModNames()
    local availableNames = {}

    for _, metadata in pairs(modHandler.modMetadata) do
        local modNames = modHandler.getModNamesFromMetadata(metadata)

        if modNames then
            for _, modName in ipairs(modNames) do
                table.insert(availableNames, modName)
            end
        end
    end

    return availableNames
end

function modHandler.formatAssociatedMods(language, modNames)
    local displayNames = {}

    for _, modName in ipairs(modNames or {}) do
        local modNameLanguage = language.mods[modName].name

        if modNameLanguage._exists then
            displayNames[tostring(modNameLanguage)] = true

        else
            displayNames[modName] = true
        end
    end

    displayNames = table.keys(displayNames)

    if #displayNames > 0 then
        table.sort(displayNames)

        local joinedNames = table.concat(displayNames, modHandler.modNamesSeparator)

        return string.format(modHandler.modNamesFormat, joinedNames)
    end
end

return modHandler