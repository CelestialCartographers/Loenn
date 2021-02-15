local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")

local targetElement
local contextMenuRoot

local contextMenuHandler = {}
local contextStack = {}

local function createContextMenu(spawnedFrom, widget)
    local x, y = love.mouse.getPosition()

    local window = uiElements.panel(widget):with({
        interactive = 2,
        updateHidden = true,

        x = -1024,
        y = -1024
    }):hook({
        update = contextMenuHandler.contextWindowUpdate
    })

    window.spawnedFrom = spawnedFrom

    table.insert(contextStack, window)
    contextMenuRoot:reflow()
    ui.root:recollect()

    ui.runLate(function()
        widgetUtils.moveWindow(window, x, y)
    end)

    return window
end

function contextMenuHandler.contextWindowUpdate(orig, self, dt)
    orig(self, dt)

    local hovering = ui.hovering

    for i = #contextStack, 1, -1 do
        local target = ui.hovering
        local contextMenu = contextStack[i]
        local spawnedFrom = i > 1 and contextStack[i + 1] or targetElement

        while target do
            if target == contextMenu or target == spawnedFrom then
                return
            end

            target = target.parent
        end

        contextStack[i]:removeSelf()
        contextStack[i] = nil
    end
end

function contextMenuHandler.showContextMenu(...)
    targetElement = ui.hovering

    local stackSize = #contextStack
    local foundTarget = false

    for i = 1, stackSize do
        local contextMenu = contextStack[i]

        if not foundTarget then
            local spawnedFrom = contextMenu.spawnedFrom

            if targetElement == spawnedFrom then
                foundTarget = true
            end
        end

        if foundTarget then
            contextMenu:removeSelf()

            contextStack[i] = nil
        end
    end

    createContextMenu(targetElement, widgetUtils.getSimpleOverlayWidget(...))
end

function contextMenuHandler.getContextMenu()
    if not contextMenuRoot then
        contextMenuRoot = uiElements.group(contextStack)
    end

    return contextMenuRoot
end

-- TODO - Use menu button from Lönn config
function contextMenuHandler.addContextMenu(target, ...)
    local arguments = {...}

    target:hook({
        onRelease = function(orig, self, x, y, button, istouch)
            if button == 2 then
                contextMenuHandler.showContextMenu(unpack(arguments))
            end
        end
    })

    return target
end

return contextMenuHandler