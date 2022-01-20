local inputDevice = require("input_device")
local sceneHandler = require("scene_handler")

local inputHandler = {}

local mouseButtonsPressed = {}
local dragTreshold = 2

local windowFocused = true
local usingMacOS = love.system.getOS() == "OS X"

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

function love.textinput(text)
    sceneHandler.sendEvent("textinput", text)
end

function love.mousemoved(x, y, dx, dy, istouch)
    -- Mouse events on Mac should only be handled if window is focused
    if not windowFocused and usingMacOS then
        return
    end

    for button, data <- mouseButtonsPressed do
        sceneHandler.sendEvent("mousedragmoved", inputHandler.getMouseDragDelta(x, y, button, istouch))
    end

    sceneHandler.sendEvent("mousemoved", x, y, dx, dy, istouch)
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Mouse events on Mac should only be handled if window is focused
    if not windowFocused and usingMacOS then
        return
    end

    mouseButtonsPressed[button] = {x, y, x, y}

    sceneHandler.sendEvent("mousepressed", x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    -- Mouse events on Mac should only be handled if window is focused
    if not windowFocused and usingMacOS then
        return
    end

    local startX, startY, dx, dy, consideredDrag = inputHandler.getMouseDrag(x, y, button)

    if consideredDrag then
        sceneHandler.sendEvent("mousedragged", startX, startY, button, dx, dy)

    else
        sceneHandler.sendEvent("mouseclicked", startX, startY, button, istouch, presses)
    end

    sceneHandler.sendEvent("mousereleased", x, y, button, istouch, presses, not consideredDrag)

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

function love.focus(focus)
    windowFocused = focus

    sceneHandler.sendEvent("focus", focus)
end

function love.filedropped(file)
    sceneHandler.sendEvent("filedropped", file)
end

function love.directorydropped(path)
    sceneHandler.sendEvent("directorydropped", path)
end

function love.quit()
    local handled, preventQuit = sceneHandler.quit()

    return preventQuit
end

return inputHandler