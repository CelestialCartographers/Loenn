local configs = require("configs")

local graphicsDevice = {}

function graphicsDevice.focused()
    DRAW_INTERVAL = configs.graphics.focused_draw_rate
    UPDATE_INTERVAL = configs.graphics.focused_update_rate
    MAIN_LOOP_SLEEP = configs.graphics.focused_main_loop_sleep
end

function graphicsDevice.unfocused()
    DRAW_INTERVAL = configs.graphics.unfocused_draw_rate
    UPDATE_INTERVAL = configs.graphics.unfocused_update_rate
    MAIN_LOOP_SLEEP = configs.graphics.unfocused_main_loop_sleep
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