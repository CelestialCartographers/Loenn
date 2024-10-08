local toolHandler = require("tools")
local toolUtils = require("tool_utils")

local state = require("loaded_state")
local viewport = require("viewport_handler")
local utils = require("utils")
local persistence = require("persistence")
local configs = require("configs")
local keyboardHelper = require("utils.keyboard")
local subLayers = require("sub_layers")

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

local function tryRoomSwap(x, y, button, istouch, presses)
    if state.map ~= nil then
        local currentTool = toolHandler.currentTool
        local actionButton = configs.editor.toolActionButton
        local addModifier = configs.editor.selectionAddModifier

        if currentTool.manualRoomLogic then
            return false
        end

        if button == actionButton then
            local mapX, mapY = viewport.getMapCoordinates(x, y)
            local itemClicked = utils.getRoomAtCoords(mapX, mapY, state.map) or utils.getFillerAtCoords(mapX, mapY, state.map)
            local addModifierHeld = keyboardHelper.modifierHeld(addModifier)
            local currentItem = state.getSelectedItem()

            if itemClicked and itemClicked ~= currentItem then
                state.selectItem(itemClicked, addModifierHeld)

                return true
            end
        end
    end
end

-- Make sure we don't send release/click events for room swaps
local consumeNextRelease = false

function device.mousereleased(x, y, button, istouch, presses, click)
    if consumeNextRelease then
        consumeNextRelease = false

        return true
    end

    local currentTool = toolHandler.currentTool

    if click then
        local consume = tryRoomSwap(x, y, button, istouch, presses)

        if consume then
            consumeNextRelease = true

            return true
        end
    end

    if currentTool and currentTool.mousereleased then
        currentTool.mousereleased(x, y, button, istouch, presses, click)
    end
end

function device.mouseclicked(x, y, button, istouch, presses)
    consumeNextRelease = false

    local consume = tryRoomSwap(x, y, button, istouch, presses)
    local currentTool = toolHandler.currentTool

    if consume then
        consumeNextRelease = true

        return true
    end

    if currentTool and currentTool.mouseclicked then
        currentTool.mouseclicked(x, y, button, istouch, presses)
    end
end

function device.editorToolChanged(tool)
    persistence.toolName = tool.name
end

function device.editorToolModeChanged(tool, mode)
    toolUtils.setPersistenceMode(tool, mode)
end

function device.editorToolLayerChanged(tool, layer, subLayer)
    local layerName = subLayers.formatLayerName(layer, subLayer)

    toolUtils.setPersistenceLayer(tool, layerName)
end

function device.editorToolMaterialChanged(tool, layer, material)
    toolUtils.setPersistenceMaterial(tool, layer, material)
end

return device