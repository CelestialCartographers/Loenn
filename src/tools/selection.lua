local state = require("loaded_state")
local utils = require("utils")
local configs = require("configs")
local viewportHandler = require("viewport_handler")
local selectionUtils = require("selections")
local drawing = require("drawing")
local colors = require("colors")
local selectionItemUtils = require("selection_item_utils")
local keyboardHelper = require("keyboard_helper")
local toolUtils = require("tool_utils")

local tool = {}

tool._type = "tool"
tool.name = "Selection"
tool.image = nil

tool.layer = "entities"
tool.validLayers = {
    "entities",
    "triggers",
    "decalsFg",
    "decalsBg"
}

local selectionRectangle = nil
local selectionCompleted = false
local selectionStartX, selectionStartY = nil ,nil
local selectionPreviews = nil

local selectionMovementKeys = {
    {"itemMoveLeft", -1, 0},
    {"itemMoveRight", 1, 0},
    {"itemMoveUp", 0, -1},
    {"itemMoveDown", 0, 1},
}

local function selectionStarted(x, y)
    selectionRectangle = utils.rectangle(x, y, 0, 0)
    selectionPreviews = nil
    selectionCompleted = false

    selectionStartX = x
    selectionStartY = y
end

local function selectionChanged(x, y, width, height)
    local room = state.getSelectedRoom()

    -- Only update if needed
    if x ~= selectionRectangle.x or y ~= selectionRectangle.y or width ~= selectionRectangle.width or height ~= selectionRectangle.height then
        selectionRectangle = utils.rectangle(x, y, width, height)
        selectionPreviews = selectionUtils.getSelectionsForRoomInRectangle(room, tool.layer, selectionRectangle)
    end
end

local function selectionFinished()
    selectionRectangle = false
    selectionCompleted = true
end

local function drawSelectionArea(room)
    if selectionRectangle then
        -- Don't render if selection rectangle is too small, weird visuals
        if selectionRectangle.width >= 1 and selectionRectangle.height >= 1 then
            viewportHandler.drawRelativeTo(room.x, room.y, function()
                drawing.callKeepOriginalColor(function()
                    local x, y = selectionRectangle.x, selectionRectangle.y
                    local width, height = selectionRectangle.width, selectionRectangle.height

                    local borderColor = colors.selectionBorderColor
                    local fillColor = colors.selectionFillColor

                    love.graphics.setColor(fillColor)
                    love.graphics.rectangle("fill", x, y, width, height)

                    love.graphics.setColor(borderColor)
                    love.graphics.rectangle("line", x, y, width, height)
                end)
            end)
        end
    end
end

local function drawSelectionPreviews(room)
    if selectionPreviews then
        local preview = not selectionCompleted

        local borderColor = preview and colors.selectionPreviewBorderColor or colors.selectionCompleteBorderColor
        local fillColor = preview and colors.selectionPreviewFillColor or colors.selectionCompleteFillColor

        -- Draw all fills then borders
        -- Greatly reduces amount of setColor calls
        -- Potentially find a better solution?
        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                for _, rectangle in ipairs(selectionPreviews) do
                    local x, y = rectangle.x, rectangle.y
                    local width, height = rectangle.width, rectangle.height

                    love.graphics.setColor(fillColor)
                    love.graphics.rectangle("fill", x, y, width, height)
                end
            end)

            drawing.callKeepOriginalColor(function()
                for _, rectangle in ipairs(selectionPreviews) do
                    local x, y = rectangle.x, rectangle.y
                    local width, height = rectangle.width, rectangle.height

                    love.graphics.setColor(borderColor)
                    love.graphics.rectangle("line", x, y, width, height)
                end
            end)
        end)
    end
end

local function handleItemMovementKeys(room, key, scancode, isrepeat)
    if not selectionPreviews then
        return
    end

    for _, movementData in ipairs(selectionMovementKeys) do
        local configKey, offsetX, offsetY = movementData[1], movementData[2], movementData[3]
        local targetKey = configs.editor[configKey]

        if not keyboardHelper.modifierHeld(configs.editor.precisionModifier) then
            offsetX *= 8
            offsetY *= 8
        end

        if targetKey == key then
            local redraw = false
            for _, item in ipairs(selectionPreviews) do
                local moved = selectionItemUtils.moveSelection(room, tool.layer, item, offsetX, offsetY)

                if moved then
                    redraw = true
                end
            end

            if redraw then
                toolUtils.redrawTargetLayer(room, tool.layer)
            end

            return true
        end
    end

    return false
end

local function handleItemDeletionKey(room, key, scancode, isrepeat)
    if not selectionPreviews then
        return
    end

    local targetKey = configs.editor.itemDelete

    if targetKey == key then
        local redraw = false

        for i = #selectionPreviews, 1, -1 do
            local item = selectionPreviews[i]
            local deleted = selectionItemUtils.deleteSelection(room, tool.layer, item)

            if deleted then
                redraw = true

                table.remove(selectionPreviews, i)
            end
        end

        if redraw then
            toolUtils.redrawTargetLayer(room, tool.layer)
        end

        return true
    end

    return false
end

function tool.mousepressed(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local px, py = toolUtils.getCursorPositionInRoom(x, y)

        if px and py then
            selectionStarted(px, py)
        end
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton

    if not selectionCompleted and love.mouse.isDown(actionButton) then
        local px, py = toolUtils.getCursorPositionInRoom(x, y)

        if px and py and selectionStartX and selectionStartY then
            local width, height = px - selectionStartX, py - selectionStartY

            selectionChanged(selectionStartX, selectionStartY, width, height)
        end
    end
end

function tool.mousereleased(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        selectionFinished()
    end
end

-- Special case
function tool.mouseclicked(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local px, py = toolUtils.getCursorPositionInRoom(x, y)

        if px and py then
            selectionChanged(px - 1, py - 1, 3, 3)
            selectionFinished()
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
            tool.layer = tool.validLayers[index]

            print("Swapping layer to " .. tool.layer)
        end
    end

    handleItemMovementKeys(room, key, scancode, isrepeat)
    handleItemDeletionKey(room, key, scancode, isrepeat)
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        drawSelectionArea(room)
        drawSelectionPreviews(room)
    end
end

return tool