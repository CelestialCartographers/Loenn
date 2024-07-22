-- TODO - Fix overlap with dropdown icon and text

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local listWidgets = require("ui.widgets.lists")
local utils = require("utils")

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

                return backingDropdown:onClick(x, y, button)
            end
        end

        return orig(self, x, y, button)
    end
end

local fieldDropdown = {}

function fieldDropdown.addDropdown(field, dropdown, searchable)
    local icon = uiElements.icon("ui:icons/drop")

    icon:layout()

    if field.height == -1 then
        field:layout()
    end

    local iconHeight = icon.height
    local parentHeight = field.height
    local centerOffset = math.floor((parentHeight - iconHeight) / 2) + 1

    icon:with(uiUtils.rightbound(-1)):with(uiUtils.at(0, centerOffset))
    icon.style.color = {0.2, 0.2, 0.2}

    dropdown.submenuParent = field
    dropdown._parentProxy = field

    field._backingDropdown = dropdown
    field:addChild(icon)
    field:hook({
        onClick = fieldDropdownOnClickHook(field, icon)
    })

    if searchable then
        local origCallback = field.cb

        field.cb = function(element, new, old)
            if origCallback then
                origCallback(element, new, old)
            end

            dropdown:filter(new, true)

            if new ~= "" then
                dropdown:revealDropdown(true)
            end
        end

        local hookOptions = {
            preventCallback = true,
            skipHooksPredicate = function()
                return dropdown.list.dropdownMenuVisible
            end
        }

        listWidgets.addSearchFieldHooks(dropdown.list, field, hookOptions)
    end

    return field
end

return fieldDropdown