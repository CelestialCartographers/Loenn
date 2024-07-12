local device = {_enabled = true, _type = "device"}

local configs = require("configs")

-- Default for no UI, offset this with UI
device.positionX = 20
device.positionY = 20

function device.draw()
    local drawX = device.positionX
    local drawY = device.positionY
    local windowWidth = love.graphics.getWidth()

    if configs.editor.displayFPS then
        love.graphics.printf("FPS: " .. tostring(love.timer.getFPS()), drawX, drawY, windowWidth, "left", 0, 3, 3)
    end
end

return device