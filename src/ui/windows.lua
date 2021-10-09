local utils = require("utils")
local debugUtils = require("debug_utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local uiRoot = require("ui.ui_root")

local windows = {}

windows.windows = {}
windows.windowHandlers = {}
windows.positions = {}

function windows.registerWindow(filename, verbose)
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local window = utils.rerequire(pathNoExt)
    local name = window.name or filenameNoExt

    windows.windowHandlers[filenameNoExt] = window

    if verbose then
        print("! Registered window '" .. name .. "' from '" .. filename .."'")
    end
end

function windows.storeWindowPositions()
    for name, window in pairs(windows.windows) do
        windows.positions[name] = {
            window.x,
            window.y
        }
    end
end

function windows.restoreWindowPositions()
    for name, window in pairs(windows.windows) do
        if windows.positions[name] then
            window.x, window.y = unpack(windows.positions[name])
        end
    end

    windows.positions = {}
end

function windows.unloadWindows()
    windows.windowHandlers = {}
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
    windows.windows = {}

    for name, window in pairs(windows.windowHandlers) do
        if window.getWindow then
            windows.windows[name] = window.getWindow()

        else
            windows.windows[name] = window
        end
    end

    return table.values(windows.windows)
end

return windows