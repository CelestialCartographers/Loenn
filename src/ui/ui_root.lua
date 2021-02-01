local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local menubar = require("ui/menubar")

local uiRoot = {}

local rootElement = nil
local windowGroup = nil

function uiRoot.updateWindows(windows)
    if not rootElement then
        windowGroup = uiElements.group(
            windows
        ):with(uiUtils.fillWidth):with(uiUtils.fillHeight(true))

        rootElement = uiElements.column({
            menubar.getMenubar(),
            windowGroup
        }):with({
            style = {
                bg = {bg = {}},
                padding = 0,
                spacing = 0,
                radius = 0
            }
        })

    else
        windowGroup.children = windows
    end
end

function uiRoot.getRootElement(windows)
    uiRoot.updateWindows(windows)

    return rootElement
end

return uiRoot