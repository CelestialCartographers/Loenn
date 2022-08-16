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

local fallbackHexColor = "ffffff"

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

-- Vanilla accepts plain numbers here, these come from the packer making "000000" into 0, etc.
-- Any other values passes straight through
local function fixNumberColor(value)
    if type(value) == "number" then
        return string.format("%06d", value)
    end

    return value
end

function colorField._MT.__index:setValue(value)
    self.currentValue = fixNumberColor(value) or fallbackHexColor
    self.field:setText(self.currentValue)
    self.field.index = #self.currentValue
end

function colorField._MT.__index:getValue()
    return self.currentValue or fallbackHexColor
end

function colorField._MT.__index:fieldValid(...)
    local current = self:getValue()
    local fieldEmpty = current == nil or #current == 0

    if fieldEmpty then
        return self._allowEmpty

    elseif self._allowXNAColors then
        local color = utils.getColor(current)

        return not not color

    else
        local parsed, r, g, b = utils.parseHexColor(current)

        return parsed
    end
end

-- Return the hex color of the XNA name if allowed
-- Otherwise return the value as it is
local function getXNAColorHex(element, value)
    local fieldEmpty = value == nil or #value == 0

    if fieldEmpty and element._allowEmpty then
        return fallbackHexColor
    end

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

        formField:notifyFieldChanged()
    end
end

local function getColorPreviewArea(element)
    local x, y = element.screenX, element.screenY
    local width, height = element.width, element.height
    local padding = element.style:get("padding") or 0
    local previewSize = height - padding * 2
    local drawX, drawY = x + width - previewSize - padding, y + padding

    return drawX, drawY, previewSize, previewSize
end

local function fieldDrawColorPreview(orig, element)
    orig(element)

    local parsed = element and element._parsed
    local r, g, b, a = element._r or 0, element._g or 0, element._b or 0, parsed and 1 or 0
    local pr, pg, pb, pa = love.graphics.getColor()

    local drawX, drawY, width, height = getColorPreviewArea(element)

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill",  drawX, drawY, width, height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill",  drawX + 1, drawY + 1, width - 2, height - 2)
    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill",  drawX + 2, drawY + 2, width - 4, height - 4)
    love.graphics.setColor(pr, pg, pb, pa)
end

local function shouldShowMenu(element, x, y, button)
    local menuButton = configs.editor.contextMenuButton
    local actionButton = configs.editor.toolActionButton

    if button == menuButton then
        return true

    elseif button == actionButton then
        local drawX, drawY, width, height = getColorPreviewArea(element)

        return utils.aabbCheckInline(x, y, 1, 1, drawX, drawY, width, height)
    end

    return false
end

function colorField.getElement(name, value, options)
    local formField = {}

    value = fixNumberColor(value)

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    local allowXNAColors = options.allowXNAColors
    local allowEmpty = options.allowEmpty

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(value or fallbackHexColor, fieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth,
        _allowXNAColors = allowXNAColors,
        _allowEmpty = allowEmpty
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
    formField._allowEmpty = allowEmpty
    formField.width = 2
    formField.elements = {
        label, fieldWithContext
    }

    return setmetatable(formField, colorField._MT)
end

return colorField