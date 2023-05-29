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

    table.insert(activeWindows, window)
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
    local x, y = 0, 0
    local previous = previousPositions[name]

    -- Don't stack windows
    if #windows > 0 then
        x = 0
        y = 0
    end

    -- Set window to center of screen if no previous position
    if previous then
        window.x, window.y = previous[1], previous[2]

    else
        window.x, window.y = -4096, -4096
        -- Needs to run pretty late to get correct size
        ui.runLate(function()
            ui.runLate(function()
                widgetUtils.centerWindow(window)
            end)
        end)
    end

    previousPositions[name] = {x, y}
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