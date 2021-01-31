local utils = require("utils")
local fileLocations = require("file_locations")
local lfs = require("lfs_ffi")

local modHandler = {}

modHandler.commonModContent = "@ModsCommon@"
modHandler.specificModContent = "$%s$"
modHandler.pluginFolderNames = {
    fileLocations.loennSimpleFolderName,
    fileLocations.loennWindowsFolderName,
    fileLocations.loennLinuxFolderName
}

modHandler.loadedMods = {}

function modHandler.findPlugins(pluginType)
    local filenames = {}

    for _, folderName in ipairs(modHandler.pluginFolderNames) do
        for modFolderName in pairs(modHandler.loadedMods) do
            local path = utils.convertToUnixPath(utils.joinpath(
                string.format(modHandler.specificModContent, modFolderName),
                folderName,
                pluginType
            ))

            utils.getFilenames(path, true, filenames, function(filename)
                return utils.fileExtension(filename) == "lua"
            end)
        end
    end

    return filenames
end

function modHandler.mountable(path)
    local attributes = lfs.attributes(path)

    if attributes and attributes.mode == "directory" then
        return true, "folder"

    elseif utils.fileExtension(path) == "zip" then
        return true, "zip"
    end

    return false
end

function modHandler.mountMod(path, force)
    local loaded = modHandler.loadedMods[path]

    if not loaded or force then
        if modHandler.mountable(path) then
            local modFolderName = utils.filename(path)
            local specificMountPoint = string.format(modHandler.specificModContent, modFolderName) .. "/"

            -- Append `/.` to trick physfs to mount the same path twice
            love.filesystem.mountUnsandboxed(path, modHandler.commonModContent .. "/", 1)
            love.filesystem.mountUnsandboxed(path .. "/.", specificMountPoint, 1)

            modHandler.loadedMods[modFolderName] = true
        end
    end

    return not loaded
end

function modHandler.mountMods(directory, force)
    directory = directory or utils.joinpath(fileLocations.getCelesteDir(), "Mods")

    for filename, dir in lfs.dir(directory) do
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