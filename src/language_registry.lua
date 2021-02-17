local utils = require("utils")
local language = require("lang")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")

local languageRegistry = {}

languageRegistry.languages = {}
languageRegistry.language = {}
languageRegistry.currentLanguageName = nil

function languageRegistry.setLanguage(name)
    languageRegistry.currentLanguageName = name
    languageRegistry.language = languageRegistry.languages[name] or {}
end

function languageRegistry.getLanguage()
    return languageRegistry.language
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
    pluginLoader.loadPlugins("lang", nil, languageRegistry.loadLanguageFile, false)
    pluginLoader.loadPlugins("ui/lang", nil, languageRegistry.loadLanguageFile, false)
end

function languageRegistry.loadExternalFiles()
    local filenames = modHandler.findLanguageFiles("lang")

    pluginLoader.loadPlugins(filenames, nil, languageRegistry.loadLanguageFile)
end

return languageRegistry