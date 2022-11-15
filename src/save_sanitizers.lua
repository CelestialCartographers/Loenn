local utils = require("utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local logging = require("logging")

local sanitizers = {}

sanitizers.registeredSanitizers = {}

-- Sets the registry to the given table (or empty one) and sets the missing Sanitizers metatable
function sanitizers.initDefaultRegistry(t)
    sanitizers.registeredSanitizers = t or {}
end

local function addHandler(handler, registerAt, filenameNoExt, filename, verbose)
    local name = handler.name or filenameNoExt

    registerAt[name] = handler

    if verbose then
        logging.info("Registered save sanitizer '" .. name .. "' from '" .. filename .."'")
    end
end

function sanitizers.registerSanitizer(filename, registerAt, verbose)
    -- Use verbose flag or default to logPluginLoading from config
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading
    registerAt = registerAt or sanitizers.registeredSanitizers

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local modMetadata = modHandler.getModMetadataFromPath(filename)

    handler._loadedFrom = filename
    handler._loadedFromModName = modHandler.getModNamesFromMetadata(modMetadata)

    utils.callIterateFirstIfTable(addHandler, handler, registerAt, filenameNoExt, filename, verbose)
end

function sanitizers.loadSanitizers(path, registerAt)
    pluginLoader.loadPlugins(path, registerAt, sanitizers.registerSanitizer)
end

function sanitizers.loadInternalSanitizers(registerAt)
    return sanitizers.loadSanitizers("save_sanitizers", registerAt)
end

function sanitizers.loadExternalSanitizers(registerAt)
    local filenames = modHandler.findPlugins("save_sanitizers")

    return sanitizers.loadSanitizers(filenames, registerAt)
end

local function safeHandlerCall(functionName, ...)
    for name, sanitizer in pairs(sanitizers.registeredSanitizers) do
        if sanitizer[functionName] then
            local success, message = pcall(sanitizer[functionName], ...)

            if not success then
                logging.warning(string.format("Failed to call %s from save sanitizer '%s'", functionName, name))
                logging.warning(debug.traceback(message))
            end

            -- Event was interupted
            if success and message == false then
                return false
            end
        end
    end

    return true
end

function sanitizers.beforeSave(filename, state)
    return safeHandlerCall("beforeSave", filename, state)
end

function sanitizers.afterSave(filename, state)
    return safeHandlerCall("afterSave", filename, state)
end

return sanitizers