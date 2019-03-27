local nuklear = require("nuklear")

local roomList = require("windows/room_list")

local uiMt = {}
uiMt.__index = {}

local uiHandler = {}

uiHandler.ui = nuklear.newUI()
uiHandler.active = true
uiHandler.windows = {
    roomList
}

function uiHandler.update(dt)
    uiHandler.ui:frameBegin()

    for i, window <- uiHandler.windows do
        window.update(uiHandler.ui)
    end

    uiHandler.active = uiHandler.ui:windowIsAnyHovered()

    uiHandler.ui:frameEnd()
end

function uiHandler.draw()
    uiHandler.ui:draw()
end

function uiHandler.rawCall(event, ...)
    return uiHandler.ui[event](uiHandler.ui, ...)
end

function uiHandler.callIfActive(event, ...)
    if uiHandler.active then
        return uiHandler.rawCall(event, ...)
    end
end

function uiHandler.keypressed(key, scancode, isrepeat)
	return uiHandler.callIfActive("keypressed", key, scancode, isrepeat)
end

-- Needs to always be called, otherwise keys can repeat when they shouldnt
function uiHandler.keyreleased(key, scancode)
    return uiHandler.rawCall("keyreleased", key, scancode)
end

-- Use raw event, Nuklear handles drag itself
function uiHandler.mousepressedraw(x, y, button, istouch, presses)
	return uiHandler.callIfActive("mousepressed", x, y, button, istouch, presses)
end

-- Needs to always be called, otherwise we can't "undrag" in a window
function uiHandler.mousereleased(x, y, button, istouch, presses)
	return uiHandler.rawCall("mousereleased", x, y, button, istouch, presses)
end

-- Needs to always be called, otherwise we can't check if any windows are hovered
function uiHandler.mousemoved(x, y, dx, dy, istouch)
	return uiHandler.rawCall("mousemoved", x, y, dx, dy, istouch)
end

function uiHandler.textinput(text)
	return uiHandler.callIfActive("textinput", text)
end

function uiHandler.wheelmoved(x, y)
	return uiHandler.callIfActive("wheelmoved", x, y)
end

return uiHandler