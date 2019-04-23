local lfs = require("lfs_ffi")
local nfd = require("nfd")
local physfs = require("physfs")

local filesystem = {}

function filesystem.filename(path, sep)
    local sep = sep or physfs.getDirSeparator()

    return path:match("[^" .. sep .. "]+$")
end

function filesystem.dirname(path, sep)
    local sep = sep or physfs.getDirSeparator()
    local path = path

    return path:match("(.*" .. sep .. ")")
end

function filesystem.joinpath(...)
    local paths = {...}
    local sep = physfs.getDirSeparator()

    return table.concat(paths, sep)
end

function filesystem.splitpath(s)
    local sep = physfs.getDirSeparator()

    return string.split(s, sep)
end

function filesystem.fileExtension(path)
    return path:match("[^.]+$")
end

function filesystem.stripExtension(path)
    return path:sub(1, #path - #filesystem.fileExtension(path) - 1)
end

filesystem.mkdir = lfs.mkdir
filesystem.chdir = lfs.chdir
filesystem.dir = lfs.dir
filesystem.rmdir = lfs.rmdir

function filesystem.isFile(path)
    local attrs = lfs.attributes(path)
    
    return attrs and attrs.mode == "file"
end

function filesystem.isDirectory(path)
    local attrs = lfs.attributes(path)

    return attrs and attrs.mode == "directory"
end

function filesystem.saveDialog(path, filter)
    -- TODO - This is a blocking call, consider running in own thread
    
    return nfd.save(filter, nil, path)
end

function filesystem.openDialog(path, filter)
    -- TODO - This is a blocking call, consider running in own thread
    
    return nfd.open(filter, nil, path)
end

return filesystem