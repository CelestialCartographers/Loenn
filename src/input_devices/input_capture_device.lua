local keyboardHelper = require("utils.keyboard")

local inputCaptureDevice = {}

local DEFAULT_TIMEOUT = 10

inputCaptureDevice._capturing = false
inputCaptureDevice._captureTime = 0
inputCaptureDevice._captureMode = nil
inputCaptureDevice._captureCallback = nil

function inputCaptureDevice.update(dt)
    inputCaptureDevice._captureTime = math.max(0, inputCaptureDevice._captureTime - dt)
    inputCaptureDevice._capturing = inputCaptureDevice._captureTime > 0
end

function inputCaptureDevice.captureKeyboardHotkey(callback, timeout)
    inputCaptureDevice._captureTime = timeout or DEFAULT_TIMEOUT
    inputCaptureDevice._captureMode = "keyboard"
    inputCaptureDevice._captureCallback = callback
end

function inputCaptureDevice.captureMouseButton(callback, timeout)
    inputCaptureDevice._captureTime = timeout or DEFAULT_TIMEOUT
    inputCaptureDevice._captureMode = "mouse"
    inputCaptureDevice._captureCallback = callback
end

function inputCaptureDevice.captureStop()
    -- Wait one frame to end capturing in terms of events
    inputCaptureDevice._captureTime = 0
    inputCaptureDevice._captureMode = nil
    inputCaptureDevice._captureCallback = nil
end

function inputCaptureDevice.keypressed(key, scancode, isrepeat)
    return inputCaptureDevice._capturing
end

function inputCaptureDevice.keyreleased(key, scancode, isrepeat)
    if inputCaptureDevice._captureMode == "keyboard" then
        if inputCaptureDevice._captureCallback then
            local activator = keyboardHelper.activatorModifierString(key)

            inputCaptureDevice._captureCallback(activator, key)
            inputCaptureDevice.captureStop()
        end
    end

    return inputCaptureDevice._capturing
end

function inputCaptureDevice.mousepressed(x, y, button, istouch, presses)
    return inputCaptureDevice._capturing
end

function inputCaptureDevice.mousereleased(x, y, button, istouch, presses)
    if inputCaptureDevice._captureMode == "mouse" then
        if inputCaptureDevice._captureCallback then
            inputCaptureDevice._captureCallback(button)
            inputCaptureDevice.captureStop()
        end
    end

    return inputCaptureDevice._capturing
end

function inputCaptureDevice.mouseclicked(x, y, button, istouch, presses)
    return inputCaptureDevice._capturing
end


return inputCaptureDevice