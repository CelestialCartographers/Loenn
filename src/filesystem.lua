local lfs = require("lfs_ffi")
local nfd = require("nfd")
local http = require("socket.http")
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

-- TODO, Sanitize parts with leading/trailing separator
-- IE {"foo", "/bar/"} becomes "foo//bar", expected "foo/bar"
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

filesystem.remove = os.remove

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
    -- TODO - Verify arguments, documentation was very existant 

    return nfd.save(filter, nil, path)
end

function filesystem.openDialog(path, filter)
    -- TODO - This is a blocking call, consider running in own thread
    -- TODO - Verify arguments, documentation was very existant 

    return nfd.open(filter, nil, path)
end

function filesystem.downloadURL(url, filename)
    local body, code, headers = http.request(url)

    if body and code == 200 then
        filesystem.mkdir(filesystem.dirname(filename))
        local fh = io.open(filename, "wb")

        if fh then
            fh:write(body)
            fh:close()

            return true
        end
    end

    return false
end

function filesystem.copyFromLoveFilesystem(mountPoint, output, folder)
    local filesTablePath = folder and filesystem.joinpath(mountPoint, folder) or mountPoint
    local filesTable = love.filesystem.getDirectoryItems(filesTablePath)

    local outputTarget = folder and filesystem.joinpath(output, folder) or output
    filesystem.mkdir(outputTarget)

    for i, file <- filesTable do
        local path = folder and filesystem.joinpath(folder, file) or file
        local mountPath = filesystem.joinpath(mountPoint, path)
        local info = love.filesystem.getInfo(mountPath)

        if info.type == "file" then
            local fh = io.open(filesystem.joinpath(output, path), "wb")

            if fh then
                local data = love.filesystem.read(mountPath)

                fh:write(data)
                fh:close()
            end

        elseif info.type == "directory" then
            filesystem.copyFromLoveFilesystem(mountPoint, output, path)
        end
    end
end

-- Unzip using phyfs unsandboxed mount system, and then manually copying out files
function filesystem.unzip(zipPath, outputDir)
    love.filesystem.mountUnsandboxed(zipPath, "temp/", 0)

    filesystem.copyFromLoveFilesystem("temp", outputDir)

    love.filesystem.unmount("temp")
end

return filesystem