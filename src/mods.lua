local utils = require("utils")
local fileLocations = require("file_locations")
local yaml = require("yaml")

local modHandler = {}

modHandler.internalModContent = "@Internal@"
modHandler.commonModContent = "@ModsCommon@"
modHandler.everestYamlFilename = "everest.yaml"
modHandler.specificModContent = "$%s$"
modHandler.pluginFolderNames = {
    fileLocations.loennSimpleFolderName,
    fileLocations.loennWindowsFolderName,
    fileLocations.loennLinuxFolderName,
    fileLocations.loennZipFolderName
}

modHandler.loadedMods = {}
modHandler.modMetadata = {}

function modHandler.findFiletype(startFolder, filetype)
    local filenames = {}

    for _, folderName in ipairs(modHandler.pluginFolderNames) do
        for modFolderName in pairs(modHandler.loadedMods) do
            local path = utils.convertToUnixPath(utils.joinpath(
                string.format(modHandler.specificModContent, modFolderName),
                folderName,
                startFolder
            ))

            utils.getFilenames(path, true, filenames, function(filename)
                return utils.fileExtension(filename) == filetype
            end)
        end
    end

    return filenames
end

function modHandler.findPlugins(pluginType)
    return modHandler.findFiletype(pluginType, "lua")
end

function modHandler.findLanguageFiles(startPath)
    startPath = startPath or "lang"

    return modHandler.findFiletype(startPath, "lang")
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
    local celesteDir = fileLocations.getCelesteDir()
    local parts = utils.splitpath(filename)

    for i = #parts, 1, -1 do
        local testPath = utils.joinpath(unpack(parts, 1, i))

        if utils.samePath(testPath, celesteDir) then
            -- Go back up two steps to get mod name, this checks for Celeste root

            return parts[i + 2]
        end
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
            return mountPoint .. "." .. folderName
        end
    end
end

function modHandler.readModEverestYaml(path, mountPoint, folderName)
    local yamlFilename = mountPoint .. "/" .. modHandler.everestYamlFilename
    local content, size = love.filesystem.read(yamlFilename)

    if content then
        local success, data = pcall(yaml.read, utils.stripByteOrderMark(content))

        if success then
            data._mountPoint = mountPoint
            data._mountPointLoenn = modHandler.findPluginLoennFolder(mountPoint)
            data._path = path
            data._folderName = folderName

            return data
        end
    end

    return {}
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
        local success, result = utils.tryrequire(libPrefix .. "." .. lib)

        if success then
            return result
        end

    else
        -- TODO - Add warning
    end
end

function modHandler.mountMod(path, force)
    local loaded = modHandler.loadedMods[path]

    if not loaded or force then
        if modHandler.mountable(path) then
            -- Replace "." in ".zip" to prevent require from getting confused
            local directory, filename = utils.dirname(path), utils.filename(path)
            local modFolderName = filename:gsub("%.", "_")
            local specificMountPoint = string.format(modHandler.specificModContent, modFolderName)

            -- Can't mount the same path twice, trick physfs into loading both
            love.filesystem.mountUnsandboxed(path, modHandler.commonModContent .. "/", 1)
            love.filesystem.mountUnsandboxed(utils.joinpath(directory, ".", filename), specificMountPoint, 1)

            local modMetadata = modHandler.readModEverestYaml(path, specificMountPoint, modFolderName)

            modHandler.loadedMods[modFolderName] = true
            modHandler.modMetadata[modFolderName] = modMetadata
        end
    end

    return not loaded
end

function modHandler.mountMods(directory, force)
    directory = directory or utils.joinpath(fileLocations.getCelesteDir(), "Mods")

    for filename, dir in utils.listDir(directory) do
        if filename ~= "." and filename ~= ".." then
            modHandler.mountMod(utils.joinpath(directory, filename), force)

            coroutine.yield()
        end
    end
end

function modHandler.realDirectory(target)
    -- TODO - Implement / Test

    return love.filesystem.getRealDirectory(modHandler.commonModContent .. "/" .. target)
end

return modHandler