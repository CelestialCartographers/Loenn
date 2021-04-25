local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")

local roomNameField = {}

roomNameField.fieldType = "room_name_unique"

roomNameField._MT = {}
roomNameField._MT.__index = {}

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function roomNameField._MT.__index:setValue(value)
    self.field:setText(value)
    self.currentValue = value
end

function roomNameField._MT.__index:getValue()
    return self.currentValue
end

function roomNameField._MT.__index:fieldValid()
    local editedRoom = self.options.editedRoom
    local currentName = self.currentValue

    if not currentName or currentName == "" then
        return false
    end

    if loadedState.map then
        for _, room in ipairs(loadedState.map.rooms) do
            if room.name == currentName and editedRoom ~= currentName then
                return false
            end
        end
    end

    return true
end

local function fieldChanged(formField)
    return function(element, new, old)
        local wasValid = formField:fieldValid()

        formField.currentValue = new

        local valid = formField:fieldValid()

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

function roomNameField.getElement(name, value, options)
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
    formField.options = options
    formField.width = 2
    formField.elements = {
        label, field
    }

    return setmetatable(formField, roomNameField._MT)
end

return roomNameField