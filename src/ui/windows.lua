local utils = require("utils")
local debugUtils = require("debug_utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local uiRoot = require("ui/ui_root")

local windows = {}

windows.loadedWindows = {}

function windows.registerWindow(filename, verbose)
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local window = utils.rerequire(pathNoExt)
    local name = window.name or filenameNoExt

    windows.loadedWindows[filenameNoExt] = window

    if verbose then
        print("! Registered window '" .. name .. "' from '" .. filename .."'")
    end
end

function windows.unloadWindows()
    windows.loadedWindows = {}
end

function windows.loadWindows(path)
    pluginLoader.loadPlugins(path, nil, windows.registerWindow, false)
end

function windows.loadInternalWindows()
    return windows.loadWindows("ui/windows")
end

function windows.loadExternalWindows(registerAt)
    local filenames = modHandler.findPlugins("ui/windows")

    return windows.loadWindows(filenames)
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

-- Add Debug UI reload function
function debugUtils.reloadUI()
    print("! Reloading windows")

    windows.unloadWindows()

    windows.loadInternalWindows()
    windows.loadExternalWindows()

    uiRoot.updateWindows(windows.getLoadedWindows())
end

return windows