local persistence = require("persistence")
local configs = require("configs")

local windowUtils = {}

function windowUtils.setFullscreen(fullscreen, fullscreenType)
    local result = love.window.setFullscreen(fullscreen, fullscreenType or "desktop")

    -- Resize events are not sent when going out of fullscreen
    if not fullscreen then
        love.event.push("resize", love.graphics.getWidth(), love.graphics.getHeight())
    end

    windowUtils.updateWindowPersistence()

    return result
end

function windowUtils.toggleFullscreen()
    local fullscreen, fullscreenType = love.window.getFullscreen()

    return windowUtils.setFullscreen(not fullscreen, fullscreenType or "desktop")
end

return windowUtils