local toolHandler = require("tool_handler")

local state = require("loaded_state")
local viewport = require("viewport_handler")
local utils = require("utils")
local configs = require("configs")

local actionButton = configs.editor.toolActionButton

local toolProxyMt = {
    __index = function(self, event)
        if state.map ~= nil then
            local currentTool = toolHandler.currentTool

            if currentTool and currentTool[event] then
                return currentTool[event]
            end
        end

        return function() end
    end
}

local device = setmetatable({_enabled = true, _type = "device"}, toolProxyMt)


-- Don't send clicks that would "swap" the target room
function device.mousepressed(x, y, button, istouch, presses)
    if state.map ~= nil then
        local currentTool = toolHandler.currentTool

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
end

return device