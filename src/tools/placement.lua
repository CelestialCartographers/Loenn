local state = require("loaded_state")
local placementUtils = require("placement_utils")
local layerHandlers = require("layer_handlers")
local viewportHandler = require("viewport_handler")
local keyboardHelper = require("keyboard_helper")
local configs = require("configs")
local utils = require("utils")
local toolUtils = require("tool_utils")

local tool = {}

tool._type = "tool"
tool.name = "Placement"
tool.image = nil

tool.layer = "entities"
tool.validLayers = {
    "entities",
    "triggers",
    "decalsFg",
    "decalsBg"
}

local placementsAvailable = {}
local placementTemplate = nil

local placementOffsetX = 0
local placementOffsetY = 0

-- Temporary simple placement selection
local placementIndex = 1

local function getPlacementOffset()
    local precise = keyboardHelper.modifierHeld(configs.editor.precisionModifier)

    if precise then
        return placementOffsetX, placementOffsetY

    else
        return math.floor(placementOffsetX / 8) * 8, math.floor(placementOffsetY / 8) * 8
    end
end

local function updatePlacementDrawable()
    if placementTemplate then
        local target = placementTemplate.placement.name
        local drawable = placementUtils.getDrawable(tool.layer, target, state.getSelectedRoom(), placementTemplate.item)

        placementTemplate.drawable = drawable
    end
end

local function selectPlacement(name, index)
    for i, placement in ipairs(placementsAvailable) do
        if i == index or placement.name == name then
            placementIndex = i
            placementTemplate = {
                item = utils.deepcopy(placement.itemTemplate),
                placement = placement,
            }

            updatePlacementDrawable()

            return true
        end
    end

    return false
end

local function drawPlacement(room)
    if room and placementTemplate and placementTemplate.drawable and placementTemplate.drawable.draw then
        viewportHandler.drawRelativeTo(room.x, room.y, function()
            placementTemplate.drawable:draw()
        end)
    end
end

function tool.layerSwapped(layer)
    if layer ~= tool.layer then
        placementsAvailable = placementUtils.getPlacements(layer)
        selectPlacement(nil, 1)

        tool.layer = layer
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local px, py = toolUtils.getCursorPositionInRoom(x, y)

    if px and py then
        placementOffsetX = px
        placementOffsetY = py
    end
end

function tool.mousepressed(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if placementTemplate and placementTemplate.item and button == actionButton then
        local room = state.getSelectedRoom()
        local copiedItem = utils.deepcopy(placementTemplate.item)

        local placed = placementUtils.placeItem(room, tool.layer, copiedItem)

        if placed then
            toolUtils.redrawTargetLayer(room, tool.layer)
        end
    end
end

function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()

    -- Debug layer swapping
    -- TODO - Remove this later
    local index = tonumber(key)

    if index then
        if index >= 1 and index <= #tool.validLayers then
            tool.layerSwapped(tool.validLayers[index])

            print("Swapping layer to " .. tool.layer)
        end
    end

    if key == "up" then
        placementIndex = math.max(placementIndex - 1, 1)
        selectPlacement(nil, placementIndex)

    elseif key == "down" then
        placementIndex = math.min(placementIndex + 1, #placementsAvailable)
        selectPlacement(nil, placementIndex)
    end
end

function tool.update(dt)
    if placementTemplate and placementTemplate.item then
        local itemX, itemY = getPlacementOffset()

        if itemX ~= placementTemplate.item.x or itemY ~= placementTemplate.item.y then
            placementTemplate.item.x = itemX
            placementTemplate.item.y = itemY

            updatePlacementDrawable()
        end
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        drawPlacement(room)
    end
end

return tool