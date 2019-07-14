local inputDevice = require("input_device")

local inputHandler = {}

local mouseButtonsPressed = {}

local dragTreshold = 2

local echoDevice = true

function inputHandler.getMouseDrag(x, y, button)
    local from = mouseButtonsPressed[button]
    local startX, startY = from[1], from[2]
    local dx, dy = x - startX, y - startY
    local consideredDrag = math.abs(dx) >= dragTreshold and math.abs(dy) >= dragTreshold

    return startX, startY, dx, dy, consideredDrag
end

function inputHandler.getMouseDragDelta(x, y, button, istouch)
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
        inputDevice.sendEvent("mousedragmoved", inputHandler.getMouseDragDelta(x, y, button, istouch))
    end

    inputDevice.sendEvent("mousemoved", x, y, dx, dy, istouch)
end

-- Don't send the event here, make sure it is not a drag first
function love.mousepressed(x, y, button, istouch, presses)
    mouseButtonsPressed[button] = {x, y, x, y}
end

function love.mousereleased(x, y, button, istouch, presses)
    inputDevice.sendEvent("mousereleased", x, y, button, istouch, presses)

    local startX, startY, dx, dy, consideredDrag = inputHandler.getMouseDrag(x, y, button)

    if consideredDrag then
        inputDevice.sendEvent("mousedrag", startX, startY, button, dx, dy)

    else
        inputDevice.sendEvent("mousepressed", startX, startY, button, istouch, presses)
    end

    mouseButtonsPressed[button] = nil
end

function love.resize(width, height)
    inputDevice.sendEvent("resize", width, height)
end

function love.wheelmoved(dx, dy)
    inputDevice.sendEvent("wheelmoved", dx, dy)
end

function love.visible(visible)
    inputDevice.sendEvent("visible", visible)
end

function love.filedropped(file)
    inputDevice.sendEvent("filedropped", file)
end

function love.directorydropped(path)
    inputDevice.sendEvent("directorydropped", path)
end

function inputHandler.update(dt)
    inputDevice.sendEvent("update", dt)
end

function inputHandler.draw()
    inputDevice.sendEvent("draw")
end

return inputHandler