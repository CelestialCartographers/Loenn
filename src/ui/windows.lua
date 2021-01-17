local utils = require("utils")

local windows = {}

windows.loadedWindows = {}

function windows.registerWindow(filename, verbose)
    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local window = utils.rerequire(pathNoExt)
    local name = window.name or filenameNoExt

    windows.loadedWindows[filenameNoExt] = window

    if verbose then
        print("! Registered window '" .. name .. "' from '" .. filename .."'")
    end
end

-- TODO - Santize user paths
function windows.loadInternalWindows(path, verbose)
    path = path or "ui/windows"

    for i, file <- love.filesystem.getDirectoryItems(path) do
        -- Always use Linux paths here
        windows.registerWindow(utils.joinpath(path, file):gsub("\\", "/"), verbose)
    end

    return windows.loadedWindows
end

function windows.getLoadedWindows()
    local res = {}

    for name, window in pairs(windows.loadedWindows) do
        if window.getWindow then
            table.insert(res, window.getWindow())

        else
            table.insert(res, window)
        end
    end

    return res
end

return windows