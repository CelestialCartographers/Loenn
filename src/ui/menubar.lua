local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

-- TODO - Implement properly
local menubar = {}

menubar.menubar = {
    {"Test 1"},
    {"Test 2"}
}

function menubar.getMenubar()
    return uiElements.topbar(menubar.menubar)
end

return menubar