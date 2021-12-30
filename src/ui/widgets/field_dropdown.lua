-- TODO - Fix overlap with dropdown icon and text

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")

local function dropdownItemOnClickHook(field, dropdown)
    -- Update the text without causing a field update
    return function(orig, self, x, y, button)
        orig(self, x, y, button)

        local newSelection = dropdown:getSelectedData() or ""

        field.label.text = newSelection
        field._text = newSelection

        field:setCursorIndex(#newSelection)
        field:repaint()
    end
end

local function getIconArea(field, icon)
    -- Calculate custom rectangle, as the image one is too small

    local iconX, iconY, iconWidth, iconHeight = icon.screenX, icon.screenY, icon.width, icon.height
    local fromRightEdge = field.screenX + field.width - iconX - iconWidth
    local fromTop = iconY - field.screenY

    local rectangleX = iconX - fromRightEdge
    local rectangleY = iconY - fromTop
    local rectangleWidth = iconWidth + fromRightEdge * 2
    local rectangleHeight = iconHeight + fromTop * 2

    return rectangleX, rectangleY, rectangleWidth, rectangleHeight
end

local function hoveringDropdownArea(field, icon, x, y)
    local rectangleX, rectangleY, rectangleWidth, rectangleHeight = getIconArea(field, icon)

    return utils.aabbCheckInline(rectangleX, rectangleY, rectangleWidth, rectangleHeight, x, y, 1, 1)
end

local function fieldDropdownOnClickHook(field, icon)
    return function(orig, self, x, y, button)
        if self.enabled and button == 1 then
            if hoveringDropdownArea(field, icon, x, y) then
                local backingDropdown = field._backingDropdown

                local menuX = field.screenX
                local menuY = field.screenY + field.height + field.parent.style.spacing

                if backingDropdown.submenu then
                    backingDropdown.submenu:removeSelf()
                end

                backingDropdown.submenu = uiElements.menuItemSubmenu.spawn(field, menuX, menuY, uiUtils.map(backingDropdown.data, function(data, i)
                    local item = backingDropdown:getItemCached(data, i):hook({
                        onClick = dropdownItemOnClickHook(field, backingDropdown)
                    })

                    item.width = false
                    item.height = false
                    item:layout()

                    return item
                end))

                return true
            end
        end

        return orig(self, x, y, button)
    end
end

local fieldDropdown = {}

function fieldDropdown.addDropdown(field, dropdown, currentText)
    local icon = uiElements.icon("ui:icons/drop"):with(uiUtils.at(0.999 + 1, 0.5 + 5))

    icon.style.color = {0.2, 0.2, 0.2}

    field.label.text = currentText
    field._text = currentText

    field._backingDropdown = dropdown
    field:addChild(icon)
    field:hook({
        onClick = fieldDropdownOnClickHook(field, icon)
    })

    return field
end

return fieldDropdown