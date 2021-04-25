local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local contextMenu = require("ui.context_menu")
local utils = require("utils")

local colorField = {}

colorField.fieldType = "hex_color"

colorField._MT = {}
colorField._MT.__index = {}

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function colorField._MT.__index:setValue(value)
    self.field:setText(value)
    self.currentValue = value
end

function colorField._MT.__index:getValue()
    return self.currentValue
end

function colorField._MT.__index:fieldValid()
    local parsed, r, g, b = utils.parseHexColor(self:getValue())

    return parsed
end

local function fieldChanged(formField)
    return function(element, new, old)
        local parsed, r, g, b = utils.parseHexColor(new)
        local wasValid = formField:fieldValid()
        local valid = parsed

        formField.currentValue = new

        if wasValid ~= valid then
            if valid then
                -- Reset to default
                formField.field.style = nil

            else
                formField.field.style = invalidStyle
            end

            formField.field:repaint()
        end
    end
end

function colorField.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(value, fieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })

    field:setPlaceholder(value)

    local element = uiElements.row({
        label,
        field
    })

    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.field = field
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.width = 2
    formField.elements = {
        label, field
    }

    return setmetatable(formField, colorField._MT)
end

return colorField