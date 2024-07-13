local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
local inputCapturingDevice = require("input_devices.input_capture_device")

local mouseField = {}

mouseField._MT = {}
mouseField._MT.__index = {}

function mouseField._MT.__index:setValue(value)
    self.field:setText(tostring(value))
    self.currentValue = value
end

function mouseField._MT.__index:getValue()
    return self.currentValue
end

function mouseField._MT.__index:fieldValid()
    return true
end

mouseField.fieldType = "mouse_button"

local function captureMouseButton(formField, buttonElement)
    local previousText = buttonElement.text
    local language = languageRegistry.getLanguage()

    buttonElement:setText(tostring(language.ui.userInput.capturing))

    return function(button)
        if button then
            local buttonText = string.format(tostring(language.ui.userInput.mouseButton), button)

            formField:setValue(button)
            formField:notifyFieldChanged()
            buttonElement:setText(buttonText)

        else
            buttonElement:setText(previousText)
        end
    end
end

function mouseField.getElement(name, value, options)
    local formField = {}

    local language = languageRegistry.getLanguage()
    local buttonText

    if value then
        buttonText = string.format(tostring(language.ui.userInput.mouseButton), value)

    else
        buttonText = tostring(language.ui.userInput.noValue)
    end

    local label = uiElements.label(options.displayName or name)
    local buttonElement = uiElements.button(buttonText, function(self, x, y, button)
        inputCapturingDevice.captureMouseButton(captureMouseButton(formField, self))
    end)

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    buttonElement:with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })

    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.field = buttonElement
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.width = 2
    formField.elements = {
        label, buttonElement
    }

    return setmetatable(formField, mouseField._MT)
end

return mouseField