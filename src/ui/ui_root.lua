local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local menubar = require("ui.menubar")
local notifications = require("ui.notification")
local tooltips = require("ui.tooltip")
local contextMenus = require("ui.context_menu")

local uiRoot = {}

local rootElement
local mainColumn
local windowGroup

function uiRoot.updateWindows(windows)
    if not windowGroup then
        windowGroup = uiElements.group(
            windows
        ):with(uiUtils.fillWidth):with(uiUtils.fillHeight(true))

    else
        windowGroup.children = windows

        windowGroup:reflow()
    end

    if not mainColumn then
        mainColumn = uiElements.column({
            menubar.getMenubar(),
            windowGroup
        }):with({
            style = {
                bg = {},
                padding = 0,
                spacing = 0,
                radius = 0
            }
        }):with(uiUtils.fill)

    else
        mainColumn.children = {
            menubar.getMenubar(),
            windowGroup
        }

        mainColumn:reflow()
    end

    if not rootElement then
        rootElement = uiElements.group({
            mainColumn,
            notifications.getPopupWindow(),
            contextMenus.getContextMenu(),
            tooltips.getTooltipWindow()
        }):with({
            style = {
                bg = {},
                padding = 0,
                spacing = 0,
                radius = 0
            }
        })

    else
        rootElement.children[1] = mainColumn

        rootElement:reflow()
    end
end

function uiRoot.getRootElement(windows)
    uiRoot.updateWindows(windows)

    return rootElement
end

return uiRoot