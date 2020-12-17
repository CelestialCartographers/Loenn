local state = require("loaded_state")
local utils = require("utils")
local configs = require("configs")
local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local selectionUtils = require("selections")
local drawing = require("drawing")
local colors = require("colors")
local itemMovement = require("item_movement")
local keyboardHelper = require("keyboard_helper")

local tool = {}

tool._type = "tool"
tool.name = "Selection"
tool.image = nil

tool.layer = "entities"

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

local function redrawTargetLayer(room)
    -- TODO - Redraw more efficiently
    celesteRender.invalidateRoomCache(room, tool.layer)
    celesteRender.invalidateRoomCache(room, "complete")
    celesteRender.forceRoomBatchRender(room, state.viewport)
end

local function updateSelectionPreviews(room)
    -- TODO - Implement
end

local function getCursorPositionInRoom(x, y)
    local room = state.getSelectedRoom()
    local px, py = nil, nil

    if room then
        px, py = viewportHandler.getRoomCoordindates(room, x, y)
    end

    return px, py
end

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
        selectionPreviews = selectionUtils.getSelectionsForRoomInRectangle(tool.layer, room, selectionRectangle)
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

local function handleitemMovementKeys(room, key, scancode, isrepeat)
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
            for _, item in ipairs(selectionPreviews) do
                itemMovement.moveSelection(tool.layer, room, item, offsetX, offsetY)
            end

            updateSelectionPreviews(room)
            redrawTargetLayer(room)

            return true
        end
    end

    return false
end

function tool.mousepressed(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local px, py = getCursorPositionInRoom(x, y)

        if px and py then
            selectionStarted(px, py)
        end
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton

    if not selectionCompleted and love.mouse.isDown(actionButton) then
        local px, py = getCursorPositionInRoom(x, y)

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
        local px, py = getCursorPositionInRoom(x, y)

        if px and py then
            selectionChanged(px - 1, py - 1, 3, 3)
            selectionFinished()
        end
    end
end

function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()

    handleitemMovementKeys(room, key, scancode, isrepeat)
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        drawSelectionArea(room)
        drawSelectionPreviews(room)
    end
end

return tool