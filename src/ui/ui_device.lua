-- Should ONLY be implemented on UI branches
-- This file is only available to reduce merge conflics between UI and master branch

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

uiElements.__label.__default.style.font = love.graphics.newFont(16)


local menubar = require("ui/menubar")
local windows = require("ui/windows")

windows.loadInternalWindows()

local uiRoot = uiElements.column({
    menubar.getMenubar(),
    uiElements.group(
        windows.getLoadedWindows()
    ):with(uiUtils.fillWidth):with(uiUtils.fillHeight(true))
}):with({
    style = {
        bg = {bg = {}},
        padding = 0,
        spacing = 0,
        radius = 0
    }
})

ui.init(uiRoot, false)

return ui