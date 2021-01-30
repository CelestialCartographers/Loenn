local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local simpleDocks = {}

local function sidePanelUpdatePosition(edge, element, parent)
    if edge == "left" then
        element.screenX = parent.screenX

    elseif edge == "right" then
        element.screenX = parent.screenX + parent.width - element.width
    end
end

local function sidePanellayoutLateLazy(edge)
    return function(orig, element)
        orig(element)

        sidePanelUpdatePosition(edge, element, element.parent)
    end
end

function simpleDocks.pinWidgetToEdge(edge, widget)
    widget:with(uiUtils.hook({
        layoutLateLazy = sidePanellayoutLateLazy(edge),
    }))

    return widget
end

return simpleDocks