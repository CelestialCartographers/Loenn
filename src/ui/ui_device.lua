-- Should ONLY be implemented on UI branches
-- This file is only available to reduce merge conflics between UI and master branch

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

uiElements.__label.__default.style.font = love.graphics.newFont(16)

uiUtils.dataRoots["ui"] = "olympUI/ui/data"

local debugUtils = require("debug_utils")
local forms = require("ui.forms.form")
local windows = require("ui.windows")
local uiRoot = require("ui.ui_root")

-- Add Debug UI reload function
function debugUtils.reloadUI()
    print("! Reloading UI elements")

    windows.storeWindowPositions()
    windows.unloadWindows()

    windows.loadInternalWindows()
    windows.loadExternalWindows()

    forms.unloadFieldTypes()

    forms.loadInternalFieldTypes()
    forms.loadExternalFieldTypes()

    uiRoot.updateWindows(windows.getLoadedWindows())

    windows.restoreWindowPositions()
end

function ui.initializeDevice()
    forms.loadInternalFieldTypes()
    forms.loadExternalFieldTypes()

    windows.loadInternalWindows()
    windows.loadExternalWindows()

    local uiRootElement = uiRoot.getRootElement(windows.getLoadedWindows())

    ui.init(uiRootElement, false)
    ui.features.eventProxies = true
    ui.features.megacanvas = true
end

return ui