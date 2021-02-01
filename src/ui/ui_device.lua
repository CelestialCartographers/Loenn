-- Should ONLY be implemented on UI branches
-- This file is only available to reduce merge conflics between UI and master branch

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

uiElements.__label.__default.style.font = love.graphics.newFont(16)


local windows = require("ui/windows")
local uiRoot = require("ui/ui_root")

windows.loadInternalWindows()
windows.loadExternalWindows()

local uiRootElement = uiRoot.getRootElement(windows.getLoadedWindows())

ui.init(uiRootElement, false)
ui.features.eventProxies = true

return ui