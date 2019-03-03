local inputDevice = require("input_device")

local mouseButtonsPressed = {}

local dragTreshold = 2

local echoDevice = true

local function getMouseDrag(x, y, button)
    local from = mouseButtonsPressed[button]
    local startX, startY = from[1], from[2]
    local dx, dy = x - startX, y - startY
    local consideredDrag = math.abs(dx) >= dragTreshold and math.abs(dy) >= dragTreshold

    return startX, startY, button, dx, dy, consideredDrag
end

local function getMouseDragDelta(x, y, button, istouch)
    local from = mouseButtonsPressed[button]
    local prevX, prevY = from[3], from[4]
    local dx, dy = x - prevX, y - prevY

    from[3] = x
    from[4] = y

    return dx, dy, button, istouch
end

function love.keypressed(key, scancode, isrepeat)
    inputDevice.sendEvent("keypressed", key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    inputDevice.sendEvent("keyreleased", key, scancode)
end

function love.mousemoved(x, y, dx, dy, istouch)
    for button, data <- mouseButtonsPressed do
        inputDevice.sendEvent("mousedragmoved", getMouseDragDelta(x, y, button, istouch))
    end

    inputDevice.sendEvent("mousemoved", x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    inputDevice.sendEvent("mousepressed", x, y, button, istouch, presses)

    mouseButtonsPressed[button] = {x, y, x, y}
end

function love.mousereleased(x, y, button, istouch, presses)
    inputDevice.sendEvent("mousereleased", x, y, button, istouch, presses)
    inputDevice.sendEvent("mousedrag", getMouseDrag(x, y, button))

    mouseButtonsPressed[button] = nil
end

function love.resize(width, height)
    inputDevice.sendEvent("resize", width, height)
end

function love.wheelmoved(dx, dy)
    inputDevice.sendEvent("wheelmoved", dx, dy)
end