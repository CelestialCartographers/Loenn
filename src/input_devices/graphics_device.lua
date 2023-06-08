local configs = require("configs")

local graphicsDevice = {}

function graphicsDevice.focused()
    DRAW_INTERVAL = configs.graphics.focusedDrawRate
    UPDATE_INTERVAL = configs.graphics.focusedUpdateRate
    MAIN_LOOP_SLEEP = configs.graphics.focusedMainLoopSleep
end

function graphicsDevice.unfocused()
    DRAW_INTERVAL = configs.graphics.unfocusedDrawRate
    UPDATE_INTERVAL = configs.graphics.unfocusedUpdateRate
    MAIN_LOOP_SLEEP = configs.graphics.unfocusedMainLoopSleep
end

function graphicsDevice.focus(focused)
    if focused then
        graphicsDevice.focused()

    else
        graphicsDevice.unfocused()
    end
end

function graphicsDevice.enter()
    graphicsDevice.focus(love.window.hasFocus())
end

return graphicsDevice