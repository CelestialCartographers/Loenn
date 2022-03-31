local themer = require("ui.utils.themer")
local modHandler = require("mods")
local utils = require("utils")
local configs = require("configs")
local logging = require("logging")

local themes = {}

themes.themes = {}
themes.currentTheme = nil

function themes.unloadThemes()
    themes.themes = {}
end

function themes.findThemes(path)
    local filenames = {}

    for _, filename in ipairs(love.filesystem.getDirectoryItems(path)) do
        local themeFolder = utils.convertToUnixPath(utils.joinpath(path, filename))
        local themeFilename = utils.convertToUnixPath(utils.joinpath(themeFolder, "theme.lua"))
        local themeFileInfo = love.filesystem.getInfo(themeFilename, "file")

        if themeFileInfo then
            table.insert(filenames, themeFilename)
        end
    end

    return filenames
end

local function loadTheme(filename, verbose)
    local pathNoExt = utils.stripExtension(filename)
    local theme = utils.rerequire(pathNoExt)

    verbose = verbose or verbose == nil and configs.debug.logPluginLoading

    if type(theme) == "table" then
        local themeName = theme.__themeName

        if type(themeName) == "string" then
            themes.themes[themeName] = theme

            if verbose then
                logging.info("Loaded theme '" .. themeName .. "' from '" .. filename .."'")
            end
        end
    end
end

function themes.loadThemes(filenames)
    -- Only load files called "theme.lua"
    -- Other files are potentially helper files or assets that should be ignored

    for _, filename in ipairs(filenames) do
        local filenameNoPath = utils.filename(filename, "/")

        if filenameNoPath == "theme.lua" then
            loadTheme(filename)
        end
    end
end

function themes.loadInternalThemes()
    local filenames = themes.findThemes("ui/themes")

    themes.loadThemes(filenames)
end

function themes.loadExternalThemes()
    local filenames = modHandler.findPlugins("ui/themes")

    themes.loadThemes(filenames)
end

function themes.useTheme(name)
    if themes.themes[name] then
        themes.currentTheme = name

        themer.apply(themes.themes[name])
    end
end

return themes