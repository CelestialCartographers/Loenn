local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")

local inputHandler = {}

local mouseButtonsPressed = {}
local dragTreshold = 2

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
    sceneHandler.sendEvent("keypressed", key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    sceneHandler.sendEvent("keyreleased", key, scancode)
end

function love.mousemoved(x, y, dx, dy, istouch)
    for button, data <- mouseButtonsPressed do
        sceneHandler.sendEvent("mousedragmoved", inputHandler.getMouseDragDelta(x, y, button, istouch))
    end

    sceneHandler.sendEvent("mousemoved", x, y, dx, dy, istouch)
end

-- Don't send the event here, make sure it is not a drag first
function love.mousepressed(x, y, button, istouch, presses)
    mouseButtonsPressed[button] = {x, y, x, y}

    sceneHandler.sendEvent("mousepressedraw", x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    local startX, startY, dx, dy, consideredDrag = inputHandler.getMouseDrag(x, y, button)

    if consideredDrag then
        sceneHandler.sendEvent("mousedrag", startX, startY, button, dx, dy)

    else
        sceneHandler.sendEvent("mousepressed", startX, startY, button, istouch, presses)
    end

    sceneHandler.sendEvent("mousereleased", x, y, button, istouch, presses)

    mouseButtonsPressed[button] = nil
end

function love.resize(width, height)
    sceneHandler.sendEvent("resize", width, height)
end

function love.wheelmoved(dx, dy)
    sceneHandler.sendEvent("wheelmoved", dx, dy)
end

function love.visible(visible)
    sceneHandler.sendEvent("visible", visible)
end

function love.filedropped(file)
    sceneHandler.sendEvent("filedropped", file)
end

function love.directorydropped(path)
    sceneHandler.sendEvent("directorydropped", path)
end

function inputHandler.update(dt)
    sceneHandler.sendEvent("update", dt)
end

function inputHandler.draw()
    sceneHandler.sendEvent("draw")
end

return inputHandler