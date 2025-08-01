local utils = require("utils")
local language = require("utils.lang")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")

local languageRegistry = {}

languageRegistry.languages = {}
languageRegistry.language = {}
languageRegistry.currentLanguageName = nil
languageRegistry.fallbackLanguage = {}
languageRegistry.fallbackLanguageName = nil

function languageRegistry.setLanguage(name)
    languageRegistry.currentLanguageName = name
    languageRegistry.language = languageRegistry.languages[name] or {}
end

function languageRegistry.getLanguage()
    return languageRegistry.language
end

function languageRegistry.setFallbackLanguage(name)
    languageRegistry.fallbackLanguageName = name
    languageRegistry.fallbackLanguage = languageRegistry.languages[name] or {}

    language.setFallback(languageRegistry.fallbackLanguage)
end

function languageRegistry.loadLanguageFile(filename)
    local name = utils.stripExtension(utils.filename(filename, "/"))
    local languageData = languageRegistry.languages[name]

    languageRegistry.languages[name] = language.loadFile(filename, languageData)
end

function languageRegistry.unloadFiles()
    languageRegistry.languages = {}
end

function languageRegistry.loadInternalFiles()
    pluginLoader.loadPlugins("lang", nil, languageRegistry.loadLanguageFile, false, "lang")
    pluginLoader.loadPlugins("ui/lang", nil, languageRegistry.loadLanguageFile, false, "lang")
end

function languageRegistry.loadExternalFiles()
    local filenames = modHandler.findLanguageFiles("lang")

    pluginLoader.loadPlugins(filenames, nil, languageRegistry.loadLanguageFile, true, "lang")
end

return languageRegistry