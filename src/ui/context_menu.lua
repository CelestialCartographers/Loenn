local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")
local configs = require("configs")

local targetElement
local contextMenuRoot

local contextMenuHandler = {}
local contextStack = {}

local function keyReleaseHook(orig, self, key, ...)
    if key == "escape" then
        -- Remove this item and all stack items after it

        local found = false

        for i, contextMenu in ipairs(contextStack) do
            if not found then
                local spawnedFrom = contextMenu.spawnedFrom

                if targetElement == spawnedFrom then
                    found = true
                end
            end

            if found then
                contextMenu:removed()
                contextMenu:removeSelf()

                contextStack[i] = nil
            end
        end

    else
        orig(self, key, ...)
    end
end

local function createContextMenu(spawnedFrom, widget, options)
    local x, y = love.mouse.getPosition()

    local window = uiElements.panel(widget):with({
        interactive = 2,
        updateHidden = true,

        x = -1024,
        y = -1024
    }):hook({
        update = contextMenuHandler.contextWindowUpdate,
        onKeyRelease = keyReleaseHook
    })

    window.spawnedFrom = spawnedFrom
    window.visibilityMode = options.mode or "hovered"
    window.removed = options.removed or function() end

    table.insert(contextStack, window)
    contextMenuRoot:layout()
    ui.root:recollect()

    ui.runLate(function()
        widgetUtils.moveWindow(window, x, y)
    end)

    return window
end

function contextMenuHandler.contextWindowUpdate(orig, self, dt)
    orig(self, dt)

    local hovering = ui.hovering
    local focusing = ui.focusing

    for i = #contextStack, 1, -1 do
        local target
        local contextMenu = contextStack[i]
        local spawnedFrom = i > 1 and contextStack[i + 1] or targetElement
        local visibilityMode = contextMenu.visibilityMode

        if visibilityMode == "hovered" then
            target = hovering

        elseif visibilityMode == "focused" then
            target = focusing or hovering
        end

        while target do
            if target == contextMenu or target == spawnedFrom then
                return
            end

            target = target._parentProxy or target.parent
        end

        contextStack[i]:removed()
        contextStack[i]:removeSelf()
        contextStack[i] = nil
    end
end

function contextMenuHandler.showContextMenu(widget, options)
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
            contextMenu:removed()
            contextMenu:removeSelf()

            contextStack[i] = nil
        end
    end

    local windowContent = widgetUtils.getSimpleOverlayWidget(widget)

    if windowContent then
        local window = createContextMenu(targetElement, windowContent, options)

        ui.focusing = window

        return window
    end
end

function contextMenuHandler.getContextMenu()
    if not contextMenuRoot then
        contextMenuRoot = uiElements.group(contextStack)
    end

    return contextMenuRoot
end

local function defaultShowMenu(customButton)
    return function(self, x, y, button, istouch)
        local menuButton = customButton or configs.editor.contextMenuButton

        return button == menuButton
    end
end

function contextMenuHandler.addContextMenu(target, widget, options)
    options = options or {}

    local shouldShowMenu = options.shouldShowMenu or defaultShowMenu(options.contextButton)

    target:hook({
        onRelease = function(orig, self, x, y, button, istouch)
            if shouldShowMenu(self, x, y, button, istouch) then
                contextMenuHandler.showContextMenu(widget, options)

            else
                orig(self, x, y, button, istouch)
            end
        end
    })

    return target
end

return contextMenuHandler