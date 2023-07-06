-- Common tool for tracking window positions
-- Most moveable windows want some form of this

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")

local windowPersister = {}

local activeWindows = {}
local previousPositions = {}

function windowPersister.getWindowCloseCallback(name)
    return function(window)
        windowPersister.removeActiveWindow(name, window)
        window:removeSelf()
    end
end

function windowPersister.removeActiveWindow(name, window)
    activeWindows[name] = activeWindows[name] or {}

    for i, w in ipairs(activeWindows[name]) do
        if w == window then
            table.remove(activeWindows, i)

            break
        end
    end

    table.insert(activeWindows, window)
end

function windowPersister.addActiveWindow(name, window)
    activeWindows[name] = activeWindows[name] or {}

    table.insert(activeWindows[name], window)
end

function windowPersister.trackWindow(name, window)
    windowPersister.addActiveWindow(name, window)
    windowPersister.restorePosition(name, window)
    windowPersister.addPositionHook(name, window)
end

function windowPersister.persistPosition(name, x, y)
    previousPositions[name] = {x, y}
end

function windowPersister.restorePosition(name, window)
    local windows = activeWindows[name]
    local previous = previousPositions[name]
    local newX, newY = -4096, -4096

    window.x, window.y = -4096, -4096

    -- Set window to center of screen if no previous position
    if previous then
        newX, newY = previous[1], previous[2]

        -- Don't stack windows
        if #windows > 0 then
            newX += 24
            newY += 24
        end
    end

    -- Needs to run pretty late to get correct size
    ui.runLate(function()
        ui.runLate(function()
            if previous then
                widgetUtils.moveWindow(window, newX, newY)

            else
                widgetUtils.centerWindow(window)
            end
        end)
    end)
end

local function windowUpdate(name, window)
    return function()
        windowPersister.persistPosition(name, window.x, window.y)
    end
end

function windowPersister.addPositionHook(name, window)
    window:with({
        updateHidden = true
    }):hook({
        update = windowUpdate(name, window)
    })
end

return windowPersister