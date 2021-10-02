-- TODO - Add history to mouse based resize and movement

local state = require("loaded_state")
local utils = require("utils")
local configs = require("configs")
local viewportHandler = require("viewport_handler")
local selectionUtils = require("selections")
local drawing = require("utils.drawing")
local colors = require("consts.colors")
local selectionItemUtils = require("selection_item_utils")
local keyboardHelper = require("utils.keyboard")
local toolUtils = require("tool_utils")
local history = require("history")
local snapshotUtils = require("snapshot_utils")
local hotkeyStruct = require("structs.hotkey")
local layerHandlers = require("layer_handlers")
local placementUtils = require("placement_utils")
local cursorUtils = require("utils.cursor")

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

local dragStartX, dragStartY = nil, nil

local selectionRectangle = nil
local selectionCompleted = false
local selectionPreviews = nil
local selectionCycleTargets = {}
local selectionCycleIndex = 1

local resizeDirection = nil
local resizeDirectionPreview = nil
local resizeLastOffsetX = nil
local resizeLastOffsetY = nil

local movementActive = false
local movementLastOffsetX = nil
local movementLastOffsetY = nil

local previousCursor = nil

local copyPreviews = nil

local selectionMovementKeys = {
    {"itemMoveLeft", -1, 0},
    {"itemMoveRight", 1, 0},
    {"itemMoveUp", 0, -1},
    {"itemMoveDown", 0, 1},
}

local selectionResizeKeys = {
    {"itemResizeLeftGrow", 1, 0, -1, 0},
    {"itemResizeRightGrow", 1, 0, 1, 0},
    {"itemResizeUpGrow", 0, 1, 0, -1},
    {"itemResizeDownGrow", 0, 1, 0, 1},
    {"itemResizeLeftShrink", -1, 0, -1, 0},
    {"itemResizeRightShrink", -1, 0, 1, 0},
    {"itemResizeUpShrink", 0, -1, 0, -1},
    {"itemResizeDownShrink", 0, -1, 0, 1}
}

local selectionFlipKeys = {
    {"itemFlipHorizontal", true, false},
    {"itemFlipVertical", false, true}
}

local selectionRotationKeys = {
    {"itemRotateLeft", -1},
    {"itemRotateRight", 1}
}

function tool.unselect()
    selectionPreviews = nil
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

local function selectionStarted(x, y)
    selectionRectangle = utils.rectangle(x, y, 0, 0)
    selectionPreviews = nil
    selectionCompleted = false
    resizeDirection = nil
    resizeDirectionPreview = nil

    dragStartX = x
    dragStartY = y
end

local function selectionFinished()
    selectionRectangle = false
    selectionCompleted = true
end

local function resizeStarted(x, y)
    dragStartX = x
    dragStartY = y
end

local function resizeFinished()
    resizeDirection = nil
    resizeDirectionPreview = nil
    resizeLastOffsetX = nil
    resizeLastOffsetY = nil
end

local function movementAttemptToActivate(cursorX, cursorY)
    if selectionPreviews and #selectionPreviews > 0 and not movementActive then
        local cursorRectangle = utils.rectangle(cursorX - 1, cursorY - 1, 3, 3)

        -- Can only start moving with cursor if we are currently over a existing selection
        for _, preview in ipairs(selectionPreviews) do
            if utils.aabbCheck(cursorRectangle, preview) then
                movementActive = true

                return true
            end
        end
    end

    return movementActive
end

local function movementStarted(x, y)
    dragStartX = x
    dragStartY = y
end

local function movementFinished()
    movementActive = false
    movementLastOffsetX = nil
    movementLastOffsetY = nil
end

local function drawSelectionArea(room)
    if selectionRectangle and not resizeDirection then
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

local function getMoveCallback(room, layer, previews, offsetX, offsetY)
    return function()
        local redraw = false

        for _, item in ipairs(previews) do
            local moved = selectionItemUtils.moveSelection(room, layer, item, offsetX, offsetY)

            if moved then
                redraw = true
            end
        end

        return redraw
    end
end

local function getResizeCallback(room, layer, previews, offsetX, offsetY, directionX, directionY)
    return function()
        local redraw = false

        for _, item in ipairs(previews) do
            local resized = selectionItemUtils.resizeSelection(room, layer, item, offsetX, offsetY, directionX, directionY)

            if resized then
                redraw = true
            end
        end

        return redraw
    end
end

local function getRotationCallback(room, layer, previews, direction)
    return function()
        local redraw = false

        for _, item in ipairs(previews) do
            local rotated = selectionItemUtils.rotateSelection(room, layer, item, direction)

            if rotated then
                redraw = true
            end
        end

        return redraw
    end
end

local function getFlipCallback(room, layer, previews, horizontal, vertical)
    return function()
        local redraw = false

        for _, item in ipairs(previews) do
            local flipped = selectionItemUtils.flipSelection(room, layer, item, horizontal, vertical)

            if flipped then
                redraw = true
            end
        end

        return redraw
    end
end

local function moveItems(room, layer, previews, offsetX, offsetY)
    local forward = getMoveCallback(room, layer, previews, offsetX, offsetY)
    local backward = getMoveCallback(room, layer, previews, -offsetX, -offsetY)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection moved")

    return snapshot, redraw
end

local function resizeItems(room, layer, previews, offsetX, offsetY, directionX, directionY)
    local forward = getResizeCallback(room, layer, previews, offsetX, offsetY, directionX, directionY)
    local backward = getResizeCallback(room, layer, previews, -offsetX, -offsetY, -directionX, -directionY)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized")

    return snapshot, redraw
end


local function rotateItems(room, layer, previews, direction)
    local forward = getRotationCallback(room, layer, previews, direction)
    local backward = getRotationCallback(room, layer, previews, -direction)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized")

    return snapshot, redraw
end

local function flipItems(room, layer, previews, horizontal, vertical)
    local forward = getFlipCallback(room, layer, previews, horizontal, vertical)
    local backward = getFlipCallback(room, layer, previews, horizontal, vertical)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized")

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

local function handleItemResizeKeys(room, key, scancode, isrepeat)
    if not selectionPreviews then
        return
    end

    for _, resizeData in ipairs(selectionResizeKeys) do
        local configKey, offsetX, offsetY, directionX, directionY = resizeData[1], resizeData[2], resizeData[3], resizeData[4], resizeData[5]
        local targetKey = configs.editor[configKey]

        if not keyboardHelper.modifierHeld(configs.editor.precisionModifier) then
            offsetX *= 8
            offsetY *= 8
        end

        if targetKey == key then
            local snapshot, redraw = resizeItems(room, tool.layer, selectionPreviews, offsetX, offsetY, directionX, directionY)

            if redraw then
                history.addSnapshot(snapshot)
                toolUtils.redrawTargetLayer(room, tool.layer)
            end

            return true
        end
    end

    return false
end

local function handleItemRotateKeys(room, key, scancode, isrepeat)
    if not selectionPreviews then
        return
    end

    for _, rotationData in ipairs(selectionRotationKeys) do
        local configKey, direction = rotationData[1], rotationData[2]
        local targetKey = configs.editor[configKey]

        if targetKey == key then
            local snapshot, redraw = rotateItems(room, tool.layer, selectionPreviews, direction)

            if redraw then
                history.addSnapshot(snapshot)
                toolUtils.redrawTargetLayer(room, tool.layer)
            end

            return true
        end
    end

    return false
end

local function handleItemFlipKeys(room, key, scancode, isrepeat)
    if not selectionPreviews then
        return
    end

    for _, flipData in ipairs(selectionFlipKeys) do
        local configKey, horizontal, vertical = flipData[1], flipData[2], flipData[3]
        local targetKey = configs.editor[configKey]

        if targetKey == key then
            local snapshot, redraw = flipItems(room, tool.layer, selectionPreviews, horizontal, vertical)

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
            local success, fromClipboard = utils.unserialize(clipboard, true, 3)

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

local function updateCursor()
    local cursor = cursorUtils.getDefaultCursor()
    local cursorResizeDirection = resizeDirection or resizeDirectionPreview

    if cursorResizeDirection then
        local horizontalDirection, verticalDirection = unpack(cursorResizeDirection)

        cursor = cursorUtils.getResizeCursor(horizontalDirection, verticalDirection)

    elseif movementActive then
        cursor = cursorUtils.getMoveCursor()
    end

    previousCursor = cursorUtils.setCursor(cursor, previousCursor)
end

local function updateSelectionPreviews(cursorX, cursorY)
    if selectionPreviews then
        local couldResize = #selectionPreviews > 0

        if couldResize then
             -- TODO - Put sensitivity in config?

            resizeDirectionPreview = nil

            local room = state.getSelectedRoom()
            local viewport = viewportHandler.viewport
            local cameraZoom = viewport.scale
            local borderThreshold = 4 / cameraZoom

            local point = utils.point(cursorX, cursorY)

            -- Find first selection where we are on the border
            for _, preview in ipairs(selectionPreviews) do
                local resizeHorizontal, resizeVertical = selectionItemUtils.canResizeItem(room, tool.layer, preview)
                local onBorder, horizontalDirection, verticalDirection = utils.onRectangleBorder(point, preview, borderThreshold)

                if not resizeHorizontal then
                    horizontalDirection = 0
                end

                if not resizeVertical then
                    verticalDirection = 0
                end

                if onBorder and (horizontalDirection ~= 0 or verticalDirection ~= 0) then
                    resizeDirectionPreview = {horizontalDirection, verticalDirection}

                    break
                end
            end
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

        -- Set up in this order: resize, move, select
        if cursorX and cursorY then
            movementAttemptToActivate(cursorX, cursorY)

            if resizeDirectionPreview then
                resizeDirection = resizeDirectionPreview

                resizeStarted(cursorX, cursorY)

            elseif movementActive then
                updateCursor()
                movementStarted(cursorX, cursorY)

            else
                selectionStarted(cursorX, cursorY)
            end
        end

        updateCursor()
    end
end

local function mouseMovedSelection(cursorX, cursorY)
    if not selectionCompleted then
        if cursorX and cursorY and dragStartX and dragStartY then
            local width, height = cursorX - dragStartX, cursorY - dragStartY

            selectionChanged(dragStartX, dragStartY, width, height)
        end
    end
end

local function mouseMovedResize(cursorX, cursorY)
    local room = state.getSelectedRoom()

    if room and cursorX and cursorY and dragStartX and dragStartY then
        local precise = keyboardHelper.modifierHeld(configs.editor.precisionModifier)
        local directionX, directionY = unpack(resizeDirection)

        local width = (cursorX - dragStartX)
        local height = (cursorY - dragStartY)

        if not precise then
            width = utils.round(width / 8) * 8
            height = utils.round(height / 8) * 8
        end

        if not resizeLastOffsetX or not resizeLastOffsetY then
            resizeLastOffsetX = width
            resizeLastOffsetY = height
        end

        if width ~= resizeLastOffsetX or height ~= resizeLastOffsetY then
            local deltaX, deltaY = width - resizeLastOffsetX, height - resizeLastOffsetY

            resizeLastOffsetX = width
            resizeLastOffsetY = height

            local snapshot, redraw = resizeItems(room, tool.layer, selectionPreviews, deltaX * directionX, deltaY * directionY, directionX, directionY)

            if redraw then
                toolUtils.redrawTargetLayer(room, tool.layer)
            end
        end
    end
end

-- TODO - Precise
local function mouseMovedMovement(cursorX, cursorY)
    local room = state.getSelectedRoom()

    if room and cursorX and cursorY and dragStartX and dragStartY then
        local precise = keyboardHelper.modifierHeld(configs.editor.precisionModifier)
        local startX, startY = dragStartX, dragStartY

        if not precise then
            cursorX = utils.round(cursorX / 8) * 8
            cursorY = utils.round(cursorY / 8) * 8

            startX = utils.round(startX / 8) * 8
            startY = utils.round(startY / 8) * 8
        end

        local deltaX = (cursorX - (movementLastOffsetX or cursorX))
        local deltaY = (cursorY - (movementLastOffsetY or cursorY))

        movementLastOffsetX = cursorX
        movementLastOffsetY = cursorY

        if deltaX ~= 0 or deltaY ~= 0 then
            local snapshot, redraw = moveItems(room, tool.layer, selectionPreviews, deltaX, deltaY)

            if redraw then
                toolUtils.redrawTargetLayer(room, tool.layer)
            end
        end
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton
    local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

    if love.mouse.isDown(actionButton) then
        -- Try in this order: resize, move, select
        if resizeDirection then
            mouseMovedResize(cursorX, cursorY)

        elseif movementActive then
            mouseMovedMovement(cursorX, cursorY)

        else
            mouseMovedSelection(cursorX, cursorY)
        end

    else
        updateSelectionPreviews(cursorX, cursorY)
    end

    updateCursor()
end

function tool.mousereleased(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        selectionFinished()
        resizeFinished()
        movementFinished()

        updateCursor()
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
            resizeFinished()
            movementFinished()
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
    handleItemResizeKeys(room, key, scancode, isrepeat)
    handleItemRotateKeys(room, key, scancode, isrepeat)
    handleItemFlipKeys(room, key, scancode, isrepeat)
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