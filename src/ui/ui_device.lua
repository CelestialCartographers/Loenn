-- Should ONLY be implemented on UI branches
-- This file is only available to reduce merge conflics between UI and master branch

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

uiUtils.dataRoots["ui"] = "olympUI/ui/data"

local debugUtils = require("debug_utils")
local forms = require("ui.forms.form")
local windows = require("ui.windows")
local uiRoot = require("ui.ui_root")
local logging = require("logging")
local themes = require("ui.themes")
local configs = require("configs")

-- Add Debug UI reload function
function debugUtils.reloadUI()
    logging.info("Reloading UI elements")

    windows.storeWindowPositions()
    windows.unloadWindows()

    windows.loadInternalWindows()
    windows.loadExternalWindows()

    forms.unloadFieldTypes()

    forms.loadInternalFieldTypes()
    forms.loadExternalFieldTypes()

    themes.unloadThemes()
    themes.loadInternalThemes()
    themes.loadExternalThemes()
    themes.useTheme(themes.currentThemeName)

    uiRoot.updateWindows(windows.getLoadedWindows())

    windows.restoreWindowPositions()
end

function ui.initializeDevice()
    themes.loadInternalThemes()
    themes.loadExternalThemes()

    local configTheme = configs.ui.theme.themeName
    local appliedTheme = themes.useTheme(configTheme)

    if not appliedTheme then
        themes.useTheme(themes.defaultThemeName)
    end

    forms.loadInternalFieldTypes()
    forms.loadExternalFieldTypes()

    windows.loadInternalWindows()
    windows.loadExternalWindows()

    local uiRootElement = uiRoot.getRootElement(windows.getLoadedWindows())

    ui.init(uiRootElement, false)
    ui.features.eventProxies = true
    ui.features.megacanvas = false
end

return ui