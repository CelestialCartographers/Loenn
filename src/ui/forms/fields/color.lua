local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local contextMenu = require("ui.context_menu")
local utils = require("utils")
local colorPicker = require("ui.widgets.color_picker")
local configs = require("configs")
local xnaColors = require("consts.xna_colors")

local colorField = {}

colorField.fieldType = "color"

colorField._MT = {}
colorField._MT.__index = {}

local previewOffset = 8
local fallbackHexColor = "ffffff"

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function colorField._MT.__index:setValue(value)
    self.currentValue = value or fallbackHexColor
    self.field:setText(self.currentValue)
    self.field.index = #self.currentValue
end

function colorField._MT.__index:getValue()
    return self.currentValue or fallbackHexColor
end

function colorField._MT.__index:fieldValid(...)
    if self._allowXNAColors then
        local color = utils.getColor(self:getValue())

        return not not color

    else
        local parsed, r, g, b = utils.parseHexColor(self:getValue())

        return parsed
    end
end

-- Return the hex color of the XNA name if allowed
-- Otherwise return the value as it is
local function getXNAColorHex(element, value)
    if element._allowXNAColors then
        local xnaColor = utils.getXNAColor(value or "")

        if xnaColor then
            return utils.rgbToHex(unpack(xnaColor))
        end
    end

    return value
end

local function cacheFieldPreviewColor(element, new)
    local parsed, r, g, b = utils.parseHexColor(getXNAColorHex(element, new))

    element._parsed = parsed
    element._r, element._g, element._b = r, g, b

    return parsed, r, g, b
end

local function fieldChanged(formField)
    return function(element, new, old)
        local parsed, r, g, b = cacheFieldPreviewColor(element, new)
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

local function getColorPreviewArea(widget)
    local x, y = widget.screenX, widget.screenY
    local width, height = widget.width, widget.height
    local previewSize = height - previewOffset * 2
    local drawX, drawY = x + width - previewSize - previewOffset, y + previewOffset

    return drawX, drawY, previewSize, previewSize
end

local function fieldDrawColorPreview(orig, widget)
    orig(widget)

    local parsed = widget and widget._parsed
    local r, g, b, a = widget._r or 0, widget._g or 0, widget._b or 0, parsed and 1 or 0
    local pr, pg, pb, pa = love.graphics.getColor()

    local drawX, drawY, width, height = getColorPreviewArea(widget)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill",  drawX, drawY, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill",  drawX + 1, drawY + 1, width - 2, height - 2)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill",  drawX + 2, drawY + 2, width - 4, height - 4)
    love.graphics.setColor(pr, pg, pb, pa)
end

local function shouldShowMenu(widget, x, y, button)
    local menuButton = configs.editor.contextMenuButton
    local actionButton = configs.editor.toolActionButton

    if button == menuButton then
        return true

    elseif button == actionButton then
        local drawX, drawY, width, height = getColorPreviewArea(widget)

        return utils.aabbCheckInline(x, y, 1, 1, drawX, drawY, width, height)
    end

    return false
end

function colorField.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    local allowXNAColors = options.allowXNAColors

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(value or fallbackHexColor, fieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth,
        _allowXNAColors = allowXNAColors
    }):hook({
        draw = fieldDrawColorPreview
    })
    local fieldWithContext = contextMenu.addContextMenu(
        field,
        function()
            local pickerOptions = {
                callback = function(data)
                    field:setText(data.hexColor)
                    field.index = #data.hexColor
                end
            }

            local fieldText = getXNAColorHex(field, field:getText() or "")

            return colorPicker.getColorPicker(fieldText, pickerOptions)
        end,
        {
            shouldShowMenu = shouldShowMenu
        }
    )

    cacheFieldPreviewColor(field, value or "")
    field:setPlaceholder(value)

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
    formField._allowXNAColors = allowXNAColors
    formField.width = 2
    formField.elements = {
        label, fieldWithContext
    }

    return setmetatable(formField, colorField._MT)
end

return colorField