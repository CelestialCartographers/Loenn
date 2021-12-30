local persistence = require("persistence")

local device = {_enabled = true, _type = "device"}

local updateRate = 2.5
local deltaTimeAcc = 0

local function persistWindowData()
    local windowX, windowY, windowDisplay = love.window.getPosition()
    local windowWidth, windowHeight = love.graphics.getDimensions()

    persistence.windowX = windowX
    persistence.windowY = windowY
    persistence.windowWidth = windowWidth
    persistence.windowHeight = windowHeight
    persistence.windowDisplay = windowDisplay
end

function device.update(dt)
    deltaTimeAcc += dt

    if deltaTimeAcc > updateRate then
        deltaTimeAcc -= updateRate

        persistWindowData()
    end
end

return device