local utils = require("utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local logging = require("logging")

local effects = {}

effects.defaultFieldOrder = {
    "name", "only", "exclude", "tag",
    "flag", "notFlag"
}
effects.defaultIgnored = {
    "_type", "_name"
}
effects.commonDefaultData = {
    flag = "",
    notflag = "",
    tag = "",
    only = "*",
    exclude = ""
}

local missingEffectHandler = require("defaults.viewer.undefined_effect")

local effectRegisteryMT = {
    __index = function() return missingEffectHandler end
}

effects.registeredEffects = nil

-- Sets the registry to the given table (or empty one) and sets the missing effects metatable
function effects.initDefaultRegistry(t)
    effects.registeredEffects = setmetatable(t or {}, effectRegisteryMT)
end

local function addHandler(handler, registerAt, filenameNoExt, filename, verbose)
    if type(handler) ~= "table" then
        return
    end

    local name = handler.name or filenameNoExt
    local modMetadata = modHandler.getModMetadataFromPath(filename)

    handler._loadedFrom = filename
    handler._loadedFromModName = modHandler.getModNamesFromMetadata(modMetadata)

    registerAt[name] = handler

    if verbose then
        logging.info("Registered effect '" .. name .. "' from '" .. filename .."'")
    end
end

function effects.registerEffect(filename, registerAt, verbose)
    -- Use verbose flag or default to logPluginLoading from config
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading
    registerAt = registerAt or effects.registeredEffects

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")
    local handler = utils.rerequire(pathNoExt)

    utils.callIterateFirstIfTable(addHandler, handler, registerAt, filenameNoExt, filename, verbose)
end

function effects.loadEffects(path, registerAt)
    pluginLoader.loadPlugins(path, registerAt, effects.registerEffect)
end

function effects.loadInternalEffects(registerAt)
    return effects.loadEffects("effects", registerAt)
end

function effects.loadExternalEffects(registerAt)
    local filenames = modHandler.findPlugins("effects")

    return effects.loadEffects(filenames, registerAt)
end

function effects.defaultData(style)
    local data = table.shallowcopy(effects.commonDefaultData)
    local handler = effects.registeredEffects[style._name]

    if handler and handler.defaultData then
        local handlerData = utils.callIfFunction(handler.defaultData, style)

        if type(handlerData) == "table" then
            for k, v in pairs(handlerData) do
                data[k] = v
            end
        end
    end

    return data
end

function effects.ignoredFields(style)
    local handler = effects.registeredEffects[style._name]

    if handler and handler.ignoredFields then
        return utils.callIfFunction(handler.ignoredFields, style)
    end

    return effects.defaultIgnored
end

function effects.fieldOrder(style)
    local handler = effects.registeredEffects[style._name]

    if handler and handler.fieldOrder then
        return utils.callIfFunction(handler.fieldOrder, style)
    end

    return effects.defaultFieldOrder
end

function effects.fieldInformation(style)
    local handler = effects.registeredEffects[style._name]

    if handler and handler.fieldInformation then
        return utils.callIfFunction(handler.fieldInformation, style)
    end

    return {}
end

function effects.canForeground(style)
    local handler = effects.registeredEffects[style._name]

    if handler and handler.canForeground ~= nil then
        return utils.callIfFunction(handler.canForeground, style)
    end

    return true
end

function effects.canBackground(style)
    local handler = effects.registeredEffects[style._name]

    if handler and handler.canBackground ~= nil then
        return utils.callIfFunction(handler.canBackground, style)
    end

    return true
end

function effects.languageData(language, style)
    local styleName = style._name

    return language.style.effects[styleName], language.style.effects.default
end

function effects.displayName(language, style)
    local name = style._name
    local displayName = utils.humanizeVariableName(name)
    local modPrefix = modHandler.getEntityModPrefix(name)
    local displayNameLanguage = language.style.effects[name].name

    if displayNameLanguage._exists then
        displayName = tostring(displayNameLanguage)
    end

    local associatedMods = effects.associatedMods(style)
    local modsString = modHandler.formatAssociatedMods(language, associatedMods)

    if modsString then
        displayName = string.format("%s %s", displayName, modsString)
    end

    return displayName
end

function effects.associatedMods(effect)
    local name = effect._name
    local handler = effects.registeredEffects[name]

    if handler then
        if handler.associatedMods then
            return utils.callIfFunction(handler.associatedMods, effect)
        end

        -- Fallback to mod containing the plugin
        return handler._loadedFromModName
    end
end

effects.initDefaultRegistry()

return effects