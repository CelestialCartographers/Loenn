local lfs = require("lfs_ffi")
local nfd = require("nfd")
local physfs = require("physfs")
local requireUtils = require("require_utils")
local threadHandler = require("thread_handler")

local hasHttps, https = requireUtils.tryrequire("https")

local filesystem = {}

filesystem.supportWindowsInThreads = love.system.getOS() ~= "OS X"

function filesystem.filename(path, sep)
    sep = sep or physfs.getDirSeparator()

    return path:match("[^" .. sep .. "]+$")
end

function filesystem.dirname(path, sep)
    sep = sep or physfs.getDirSeparator()

    return path:match("(.*" .. sep .. ")")
end

-- TODO - Sanitize parts with leading/trailing separator
-- IE {"foo", "/bar/"} becomes "foo//bar", expected "foo/bar"
function filesystem.joinpath(...)
    local paths = {...}
    local sep = physfs.getDirSeparator()

    return table.concat(paths, sep)
end

function filesystem.splitpath(s)
    local sep = physfs.getDirSeparator()

    return string.split(s, sep)()
end

function filesystem.samePath(path1, path2)
    local userOS = love.system.getOS()

    if userOS == "Windows" then
        return path1:lower() == path2:lower()

    else
        return path1 == path2
    end
end

function filesystem.fileExtension(path)
    return path:match("[^.]+$")
end

function filesystem.stripExtension(path)
    return path:sub(1, #path - #filesystem.fileExtension(path) - 1)
end

function filesystem.mkdir(path, mode)
    return lfs.mkdir(path, mode or 755)
end

filesystem.chdir = lfs.chdir
filesystem.dir = lfs.dir
filesystem.rmdir = lfs.rmdir

filesystem.remove = os.remove

-- Use Unix paths
local function findRecursive(filenames, path, recursive, predicate, useYields)
    useYields = useYields or useYields == nil

    for i, filename in ipairs(love.filesystem.getDirectoryItems(path)) do
        local fullPath = path .. "/" .. filename
        local fileInfo = love.filesystem.getInfo(fullPath)

        if useYields and i % 25 == 0 then
            coroutine.yield()
        end

        if fileInfo and fileInfo.type == "file" then
            if predicate then
                if predicate(filename) then
                    table.insert(filenames, fullPath)
                end

            else
                table.insert(filenames, fullPath)
            end

        else
            if recursive or recursive == nil then
                findRecursive(filenames, fullPath, recursive, predicate, useYields)
            end
        end
    end
end

function filesystem.getFilenames(path, recursive, filenames, predicate, useYields)
    filenames = filenames or {}

    findRecursive(filenames, path, recursive, predicate, useYields)

    return filenames
end

function filesystem.isFile(path)
    local attrs = lfs.attributes(path)

    return attrs and attrs.mode == "file"
end

function filesystem.isDirectory(path)
    local attrs = lfs.attributes(path)

    return attrs and attrs.mode == "directory"
end

function filesystem.mtime(path)
    local attrs = lfs.attributes(path)

    return attrs and attrs.modification or -1
end

-- TODO - Test
function filesystem.copy(from, to)
    local fromFh = io.open(from, "rb")

    if not fromFh then
        return false, "Target file not found"
    end

    local toFh = io.open(to, "wb")

    if not toFh then
        return false, "Couldn't create destination file"
    end

    toFh:write(fromFh:read("*a"))
    toFh:close()
    fromFh:close()

    return true
end

-- Return thread if called with callback
-- Otherwise block and return the selected file
function filesystem.saveDialog(path, filter, callback)
    -- TODO - Verify arguments, documentation was very existant

    if callback then
        if filesystem.supportWindowsInThreads then
            local code = [[
                local args = {...}
                local channelName, path, filter = unpack(args)
                local channel = love.thread.getChannel(channelName)

                local nfd = require("nfd")

                local res = nfd.save(filter, nil, path)
                channel:push(res)
            ]]

            return threadHandler.createStartWithCallback(code, callback, path, filter)

        else
            callback(nfd.save(filter, nil, path))

            return false, false
        end

    else
        return nfd.save(filter, nil, path)
    end
end

-- Return thread if called with callback
-- Otherwise block and return the selected file
function filesystem.openDialog(path, filter, callback)
    -- TODO - Verify arguments, documentation was very existant

    if callback then
        if filesystem.supportWindowsInThreads then
            local code = [[
                local args = {...}
                local channelName, path, filter = unpack(args)
                local channel = love.thread.getChannel(channelName)

                local nfd = require("nfd")

                local res = nfd.open(filter, nil, path)
                channel:push(res)
            ]]

            return threadHandler.createStartWithCallback(code, callback, path, filter)

        else
            callback(nfd.open(filter, nil, path))

            return false, false
        end

    else
        return nfd.open(filter, nil, path)
    end
end

function filesystem.downloadURL(url, filename, headers)
    if not hasHttps then
        return false, nil
    end

    local code, body, requestHeaders = https.request(url, {
        headers = headers or {
            ["User-Agent"] = "curl/7.58.0",
            ["Accept"] = "*/*"
        }
    })

    if body and code == 200 then
        filesystem.mkdir(filesystem.dirname(filename))
        local fh = io.open(filename, "wb")

        if fh then
            fh:write(body)
            fh:close()

            return true
        end

    elseif code >= 300 and code <= 399 then
        local redirect = requestHeaders["Location"]:match("^%s*(.*)%s*$")

        return filesystem.downloadURL(redirect, filename, headers)
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