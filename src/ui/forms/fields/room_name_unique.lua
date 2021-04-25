local stringField = require("ui.forms.fields.string")
local utils = require("utils")
local loadedState = require("loaded_state")

local roomNameField = {}

roomNameField.fieldType = "room_name_unique"


function roomNameField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    options.validator = function(v)
        local editedRoom = options.editedRoom
        local currentName = v

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

    return stringField.getElement(name, value, options)
end

return roomNameField