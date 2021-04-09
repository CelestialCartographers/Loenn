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
local history = require("history")
local snapshotUtils = require("snapshot_utils")
local hotkeyStruct = require("structs.hotkey")
local layerHandlers = require("layer_handlers")
local placementUtils = require("placement_utils")

local tool = {}

tool._type = "tool"
tool.name = "selection"
tool.group = "placement"
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
local selectionCycleTargets = {}
local selectionCycleIndex = 1

local copyPreviews = nil

local selectionMovementKeys = {
    {"itemMoveLeft", -1, 0},
    {"itemMoveRight", 1, 0},
    {"itemMoveUp", 0, -1},
    {"itemMoveDown", 0, 1},
}

function tool.unselect()
    selectionPreviews = nil
end

local function selectionStarted(x, y)
    selectionRectangle = utils.rectangle(x, y, 0, 0)
    selectionPreviews = nil
    selectionCompleted = false

    selectionStartX = x
    selectionStartY = y
end

local function selectionChanged(x, y, width, height, fromClick)
    local room = state.getSelectedRoom()

    -- Only update if needed
    if fromClick or x ~= selectionRectangle.x or y ~= selectionRectangle.y or math.abs(width) ~= selectionRectangle.width or math.abs(height) ~= selectionRectangle.height then
        selectionRectangle = utils.rectangle(x, y, width, height)

        local newSelections = selectionUtils.getSelectionsForRoomInRectangle(room, tool.layer, selectionRectangle)

        if fromClick then
            selectionUtils.orderSelectionsByScore(newSelections)

            if #newSelections > 0 and utils.equals(newSelections, selectionCycleTargets, false) then
                selectionCycleIndex = utils.mod1(selectionCycleIndex + 1, #newSelections)

            else
                selectionCycleIndex = 1
            end

            selectionCycleTargets = newSelections
            selectionPreviews = {selectionCycleTargets[selectionCycleIndex]}

        else
            selectionPreviews = newSelections
            selectionCycleTargets = {}
            selectionCycleIndex = 0
        end
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

local function drawItemSelections(room)
    if selectionPreviews then
        local drawnItems = {}
        local color = selectionCompleted and colors.selectionCompleteNodeLineColor or colors.selectionPreviewNodeLineColor

        viewportHandler.drawRelativeTo(room.x, room.y, function()
            for _, preview in ipairs(selectionPreviews) do
                local item = preview.item

                if not drawnItems[item] then
                    drawnItems[item] = true

                    selectionItemUtils.drawSelected(room, preview.layer, item, color)
                end
            end
        end)
    end
end

local function drawSelectionRectangles(room)
    if selectionPreviews then
        local preview = not selectionCompleted

        local borderColor = preview and colors.selectionPreviewBorderColor or colors.selectionCompleteBorderColor
        local fillColor = preview and colors.selectionPreviewFillColor or colors.selectionCompleteFillColor

        -- Draw all fills then borders
        -- Greatly reduces amount of setColor calls
        -- Potentially find a better solution?
        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(fillColor)

                for _, rectangle in ipairs(selectionPreviews) do
                    local x, y = rectangle.x, rectangle.y
                    local width, height = rectangle.width, rectangle.height

                    love.graphics.rectangle("fill", x, y, width, height)
                end
            end)

            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(borderColor)

                for _, rectangle in ipairs(selectionPreviews) do
                    local x, y = rectangle.x, rectangle.y
                    local width, height = rectangle.width, rectangle.height

                    love.graphics.rectangle("line", x, y, width, height)
                end
            end)
        end)
    end
end

local function moveItems(room, layer, previews, offsetX, offsetY)
    local snapshot, redraw, selectionsBefore = snapshotUtils.roomLayerSnapshot(function()
        local redraw = false
        local selectionsBefore = utils.deepcopy(selectionPreviews)

        for _, item in ipairs(previews) do
            local moved = selectionItemUtils.moveSelection(room, layer, item, offsetX, offsetY)

            if moved then
                redraw = true
            end
        end

        return redraw, selectionsBefore
    end, room, layer, "Selection Moved")

    return snapshot, redraw
end

local function deleteItems(room, layer, previews)
    local snapshot, redraw, selectionsBefore = snapshotUtils.roomLayerSnapshot(function()
        local redraw = false
        local selectionsBefore = utils.deepcopy(selectionPreviews)

        for i = #previews, 1, -1 do
            local item = previews[i]
            local deleted = selectionItemUtils.deleteSelection(room, layer, item)

            if deleted then
                redraw = true

                table.remove(selectionPreviews, i)
            end
        end

        return redraw, selectionsBefore
    end, room, layer, "Selection Deleted")

    return snapshot, redraw
end

local function addNode(room, layer, previews)
    local snapshot, redraw, selectionsBefore = snapshotUtils.roomLayerSnapshot(function()
        local redraw = false
        local selectionsBefore = utils.deepcopy(selectionPreviews)
        local newPreviews = {}

        for _, selection in ipairs(previews) do
            local added = selectionItemUtils.addNodeToSelection(room, layer, selection)

            if added then
                local item = selection.item
                local node = selection.node

                -- Make sure selection nodes for the target is correct
                for _, target in ipairs(previews) do
                    if target.item == item then
                        if target.node >= node then
                            target.node += 1
                        end
                    end
                end

                -- Add new node to selections
                local rectangles = selectionUtils.getSelectionsForItem(room, layer, item)

                -- Nodes are off by one here since the main entity would be the first rectangle
                -- We also insert after the target node, meaning the total offset is two
                table.insert(newPreviews, rectangles[node + 2])

                redraw = true
            end
        end

        for _, newPreview in ipairs(newPreviews) do
            table.insert(previews, newPreview)
        end

        return redraw, selectionsBefore
    end, room, layer, "Node Added")

    return snapshot, redraw
end

local function getPreviewsCorners(previews)
    local tlx, tly = math.huge, math.huge
    local brx, bry = -math.huge, -math.huge

    for _, preview in ipairs(previews or selectionPreviews) do
        tlx = math.min(tlx, preview.x)
        tly = math.min(tly, preview.y)

        brx = math.max(brx, preview.x + preview.width)
        bry = math.max(bry, preview.y + preview.height)
    end

    return tlx, tly, brx, bry
end

-- TODO - Improve decal logic, currently can't copy paste between bg <-> fg
local function pasteItems(room, layer, previews)
    local pasteCentered = configs.editor.pasteCentered
    local snapshot, usedLayers = snapshotUtils.roomLayerSnapshot(function()
        local layerItems = {}

        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(viewportHandler.getMousePosition())

        local tlx, tly, brx, bry = getPreviewsCorners(previews)
        local width, height = brx - tlx, bry - tly
        local widthOffset = pasteCentered and math.floor(width / 2) or 0
        local heightOffset = pasteCentered and math.floor(height / 2) or 0

        -- Make sure items that are already on the grid stay on it
        local offsetX, offsetY = cursorX - tlx - widthOffset, cursorY - tly - heightOffset
        local offsetGridX, offsetGridY = placementUtils.getGridPosition(offsetX, offsetY, false)

        for _, preview in ipairs(previews) do
            local item = preview.item
            local targetLayer = preview.layer

            placementUtils.finalizePlacement(room, layer, item)

            item.x = item.x + offsetGridX
            item.y = item.y + offsetGridY
            preview.x = preview.x + offsetGridX
            preview.y = preview.y + offsetGridY

            local targetItems = layerItems[targetLayer]

            if not targetItems then
                local handler = layerHandlers.getHandler(targetLayer)

                if handler and handler.getRoomItems then
                    targetItems = handler.getRoomItems(room, targetLayer)
                    layerItems[targetLayer] = targetItems
                end
            end

            if targetItems then
                table.insert(targetItems, item)
            end
        end

        selectionPreviews = previews

        return table.keys(layerItems)
    end, room, layer, "Selection Pasted")

    return snapshot, usedLayers
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
            local snapshot, redraw = moveItems(room, tool.layer, selectionPreviews, offsetX, offsetY)

            if redraw then
                history.addSnapshot(snapshot)
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
        local snapshot, redraw = deleteItems(room, tool.layer, selectionPreviews)

        if redraw then
            history.addSnapshot(snapshot)
            toolUtils.redrawTargetLayer(room, tool.layer)
        end

        return true
    end

    return false
end

local function handleNodeAddKey(room, key, scancode, isrepeat)
    if not selectionPreviews then
        return
    end

    local targetKey = configs.editor.itemAddNode

    if targetKey == key then
        local snapshot, redraw = addNode(room, tool.layer, selectionPreviews)

        if redraw then
            history.addSnapshot(snapshot)
            toolUtils.redrawTargetLayer(room, tool.layer)
        end

        return true
    end

    return false
end

local function copyCommon(cut)
    local room = state.getSelectedRoom()
    local useClipboard = configs.editor.copyUsesClipboard

    if not room or #selectionPreviews == 0 then
        return false
    end

    copyPreviews = utils.deepcopy(selectionPreviews)

    if cut then
        local snapshot, redraw = deleteItems(room, tool.layer, selectionPreviews)

        if redraw then
            history.addSnapshot(snapshot)
            toolUtils.redrawTargetLayer(room, tool.layer)
        end
    end

    if useClipboard then
        local success, text = utils.serialize(copyPreviews)

        if success then
            love.system.setClipboardText(text)
        end
    end

    return true
end

-- Attempt to prevent arbitrary code execution
local function validateClipboard(text)
    if not text or text:sub(1, 1) ~= "{" or text:sub(-1, -1) ~= "}" then
        return false
    end

    return true
end

local function copyItemsHotkey()
    copyCommon(false)
end

local function cutItemsHotkey()
    copyCommon(true)
end

local function pasteItemsHotkey()
    local useClipboard = configs.editor.copyUsesClipboard
    local newPreviews = utils.deepcopy(copyPreviews)

    if useClipboard then
        local clipboard = love.system.getClipboardText()

        if validateClipboard(clipboard) then
            local success, fromClipboard = utils.unserialize(clipboard)

            if success then
                newPreviews = fromClipboard
            end
        end
    end

    if newPreviews and #newPreviews > 0 then
        local room = state.getSelectedRoom()
        local snapshot, usedLayers = pasteItems(room, tool.layer, newPreviews)

        history.addSnapshot(snapshot)
        toolUtils.redrawTargetLayer(room, tool.layer)

        for _, layer in ipairs(usedLayers) do
            toolUtils.redrawTargetLayer(room, layer)
        end
    end
end

local toolHotkeys = {
    hotkeyStruct.createHotkey(configs.hotkeys.itemsCopy, copyItemsHotkey),
    hotkeyStruct.createHotkey(configs.hotkeys.itemsPaste, pasteItemsHotkey),
    hotkeyStruct.createHotkey(configs.hotkeys.itemsCut, cutItemsHotkey)
}

function tool.mousepressed(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY then
            selectionStarted(cursorX, cursorY)
        end
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton

    if not selectionCompleted and love.mouse.isDown(actionButton) then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY and selectionStartX and selectionStartY then
            local width, height = cursorX - selectionStartX, cursorY - selectionStartY

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
    local contextMenuButton = configs.editor.contextMenuButton

    if button == actionButton then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY then
            selectionChanged(cursorX - 1, cursorY - 1, 3, 3, true)
            selectionFinished()
        end

    elseif button == contextMenuButton then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY then
            local room = state.getSelectedRoom()
            local previewTargets = selectionUtils.getContextSelections(room, tool.layer, cursorX, cursorY, selectionPreviews)

            selectionUtils.sendContextMenuEvent(previewTargets)
        end
    end
end

function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()

    if not isrepeat then
        hotkeyStruct.callbackFirstActive(toolHotkeys)
    end

    handleItemMovementKeys(room, key, scancode, isrepeat)
    handleItemDeletionKey(room, key, scancode, isrepeat)
    handleNodeAddKey(room, key, scancode, isrepeat)
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        drawSelectionArea(room)
        drawItemSelections(room)
        drawSelectionRectangles(room)
    end
end

return tool