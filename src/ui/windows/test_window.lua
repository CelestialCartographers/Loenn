local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local testWindow = {}

function testWindow.getWindow()
    return uiElements.window("Hello, World!",
        uiElements.column({
            uiElements.label("Hello"),
            uiElements.label("World!")
        }):with({width = 200, height = 200})
    )
end

return testWindow