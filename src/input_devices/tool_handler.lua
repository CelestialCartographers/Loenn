local currentTool = {}

local state = require("loaded_state")
local viewport = require("viewport_handler")
local utils = require("utils")

-- TODO - Put in config/constants files
-- Button that is considered a "click" for tools, such as painting a tile or placing entity
local actionButton = 1

local device = {_enabled = true}

function device.mousepressed(x, y, button, istouch, presses)
    if button == actionButton then
        local mapX, mapY = viewport.getMapCoordinates(x, y)

        local roomClicked = utils.getRoomAtCoords(mapX, mapY, state.map)

        if roomClicked and roomClicked ~= state.selectedRoom then
            state.selectedRoom = roomClicked

            return true
        end
    end

    -- Send event to current tool
end

return device