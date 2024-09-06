local keyboardHelper = require("utils.keyboard")

local inputCaptureDevice = {}

local DEFAULT_TIMEOUT = 5

inputCaptureDevice._capturing = false
inputCaptureDevice._captureTime = 0
inputCaptureDevice._captureMode = nil
inputCaptureDevice._captureCallback = nil

function inputCaptureDevice.update(dt)
    if inputCaptureDevice._capturing then
        inputCaptureDevice._captureTime = math.max(0, inputCaptureDevice._captureTime - dt)

        if inputCaptureDevice._captureTime == 0 then
            inputCaptureDevice._captureCallback(false)

            inputCaptureDevice._captureMode = nil
            inputCaptureDevice._captureCallback = nil
        end
    end

    inputCaptureDevice._capturing = inputCaptureDevice._captureTime > 0
end

function inputCaptureDevice.captureKeyboardHotkey(callback, timeout)
    inputCaptureDevice._captureTime = timeout or DEFAULT_TIMEOUT
    inputCaptureDevice._captureMode = "keyboard"
    inputCaptureDevice._captureCallback = callback
end

function inputCaptureDevice.captureKeyboardModifier(callback, timeout)
    inputCaptureDevice._captureTime = timeout or DEFAULT_TIMEOUT
    inputCaptureDevice._captureMode = "keyboardModifier"
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
    if inputCaptureDevice._captureMode == "keyboardModifier" then
        if inputCaptureDevice._captureCallback then
            local activator = keyboardHelper.activatorModifierString()

            inputCaptureDevice._captureCallback(activator)
            inputCaptureDevice.captureStop()
        end
    end

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
