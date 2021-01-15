-- Should ONLY be implemented on UI branches
-- This file is only available to reduce merge conflics between UI and master branch

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

uiElements.__label.__default.style.font = love.graphics.newFont(16)

local uiRoot = uiElements.column({
    uiElements.topbar({
        {"Test 1"},
        {"Test 2"}
    }),
    uiElements.group({
        uiElements.window("Hello, World!",
            uiElements.column({
                uiElements.label("Hello"),
                uiElements.label("World!")
            }):with({width = 200, height = 200})
        ):with({x = 50, y = 50})
    }):with(uiUtils.fillWidth):with(uiUtils.fillHeight(true))
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