local currentTool = require("tools/brush")

local state = require("loaded_state")
local viewport = require("viewport_handler")
local utils = require("utils")

-- TODO - Put in config/constants files
-- Button that is considered a "click" for tools, such as painting a tile or placing entity
local actionButton = 1

local toolProxyMt = {
    __index = function(self, event)
        if currentTool and currentTool[event] then
            return currentTool[event]
        end

        return function() end
    end
}

local device = setmetatable({_enabled = true, _type = "device"}, toolProxyMt)


-- Don't send clicks that would "swap" the target room
function device.mousepressed(x, y, button, istouch, presses)
    if button == actionButton then
        local mapX, mapY = viewport.getMapCoordinates(x, y)

        local roomClicked = utils.getRoomAtCoords(mapX, mapY, state.map)

        if roomClicked and roomClicked ~= state.selectedRoom then
            state.selectedRoom = roomClicked

            return true
        end
    end

    if currentTool and currentTool.mousepressed then
        currentTool.mousepressed(x, y, button, istouch, presses)
    end
end

return device