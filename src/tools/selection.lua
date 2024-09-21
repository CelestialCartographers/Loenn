-- TODO - Add history to mouse based resize and movement
-- TODO - Look into selections targets after redo/undo

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
local layerHandlers = require("layer_handlers")
local placementUtils = require("placement_utils")
local cursorUtils = require("utils.cursor")
local nodeStruct = require("structs.node")
local tiles = require("tiles")
local hotkeyHandler = require("hotkey_handler")
local subLayers = require("sub_layers")

local tool = {}

tool._type = "tool"
tool.name = "selection"
tool.group = "placement"
tool.image = nil

tool.layer = "entities"
tool.subLayer = 0
tool.validLayers = {
    "allLayers",
    "tilesFg",
    "tilesBg",
    "entities",
    "triggers",
    "decalsFg",
    "decalsBg"
}

local allLayers = {
    _persistenceName = "AllLayers",

    "tilesFg",
    "tilesBg",
    "entities",
    "triggers",
    "decalsFg",
    "decalsBg"
}

local dragStartX, dragStartY = nil, nil
local coverStartX, coverStartY, coverStartWidth, coverStartyHeight = nil, nil, nil, nil
local dragMovementTotalX, dragMovementTotalY = 0, 0

local selectionRectangle = nil
local selectionCompleted = true
local selectionTargets = state.selectionToolTargets
local selectionPreviews = state.selectionToolPreviews
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

local copyTargets = nil

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

function tool.getSelectionTargets()
    return state.selectionToolTargets
end

function tool.getSelectionPreviews()
    return state.selectionToolPreviews
end

function tool.setSelectionTargets(targets)
    state.selectionToolTargets = targets
    selectionTargets = targets
end

function tool.setSelectionPreviews(previews)
    state.selectionToolPreviews = previews
    selectionPreviews = previews
end

function tool.setLayer(layer, subLayer)
    if layer == "allLayers" then
        tool.layer = allLayers

        -- Set all layers to forced visible
        subLayers.setLayerForceRender(layer, subLayer, true, true)

    else
        tool.layer = layer

        -- Set all layers to forced visible
        state.setLayerForceRender(layer, subLayer, true)
    end

    tool.subLayer = subLayer

    toolUtils.sendLayerEvent(tool, layer, subLayer)

    return false
end

local function selectionChanged(x, y, width, height, fromClick)
    local room = state.getSelectedRoom()

    -- Only update if needed
    if fromClick or not selectionRectangle or x ~= selectionRectangle.x or y ~= selectionRectangle.y or math.abs(width) ~= selectionRectangle.width or math.abs(height) ~= selectionRectangle.height then
        selectionRectangle = utils.rectangle(x, y, width, height)
        selectionRectangle.fromClick = fromClick

        local newSelections = selectionUtils.getSelectionsForRoomInRectangle(room, tool.layer, tool.subLayer, selectionRectangle)

        if fromClick then
            selectionUtils.orderSelectionsByScore(newSelections)

            if #newSelections > 0 and utils.equals(newSelections, selectionCycleTargets, false) then
                selectionCycleIndex = utils.mod1(selectionCycleIndex + 1, #newSelections)

            else
                selectionCycleIndex = 1
            end

            selectionCycleTargets = newSelections
            tool.setSelectionPreviews({selectionCycleTargets[selectionCycleIndex]})

        else
            tool.setSelectionPreviews(newSelections)
            selectionCycleTargets = {}
            selectionCycleIndex = 0
        end
    end
end

local function movementAttemptToActivate(cursorX, cursorY)
    if selectionTargets and #selectionTargets > 0 and not movementActive then
        local cursorRectangle = utils.rectangle(cursorX - 1, cursorY - 1, 3, 3)

        -- Can only start moving with cursor if we are currently over a existing selection
        for _, preview in ipairs(selectionTargets) do
            if utils.aabbCheck(cursorRectangle, preview) then
                movementActive = true

                return true
            end
        end
    end

    return movementActive
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

                    local lineWidth = love.graphics.getLineWidth()

                    love.graphics.setColor(fillColor)
                    love.graphics.rectangle("fill", x, y, width, height)

                    love.graphics.setColor(borderColor)
                    love.graphics.rectangle("line", x - lineWidth / 2, y - lineWidth / 2, width + lineWidth, height + lineWidth)
                end)
            end)
        end
    end
end

local function drawItemSelections(room )
    local drawnItems = {}
    local completeColor = colors.selectionCompleteNodeLineColor
    local previewColor = colors.selectionPreviewNodeLineColor

    viewportHandler.drawRelativeTo(room.x, room.y, function()
            for _, preview in ipairs(selectionPreviews) do
                local item = preview.item

                if not drawnItems[item] then
                    drawnItems[item] = true

                    selectionItemUtils.drawSelected(room, preview.layer, item, previewColor)
                end
            end

        for _, target in ipairs(selectionTargets) do
            local item = target.item

            if not drawnItems[item] then
                drawnItems[item] = true

                selectionItemUtils.drawSelected(room, target.layer, item, completeColor)
            end
        end
    end)
end

local function drawSelectionRectanglesCommon(room, targets, borderColor, fillColor, lineWidth, alreadyDrawn)
    alreadyDrawn = alreadyDrawn or {}

    if targets then
        -- Draw all fills then borders
        -- Greatly reduces amount of setColor calls
        -- TODO - See if we can use sprite batches here
        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(fillColor)

                for _, target in ipairs(targets) do
                    local x, y = target.x, target.y
                    local width, height = target.width, target.height

                    if not alreadyDrawn[target.item] then
                        love.graphics.rectangle("fill", x, y, width, height)
                    end
                end
            end)

            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(borderColor)

                for _, target in ipairs(targets) do
                    local x, y = target.x, target.y
                    local width, height = target.width, target.height

                    local item = target.item
                    local node = target.node or 0

                    alreadyDrawn[item] = alreadyDrawn[item] or {}

                    if not alreadyDrawn[item][node] then
                        love.graphics.rectangle("line", x - lineWidth / 2, y - lineWidth / 2, width + lineWidth, height + lineWidth)

                        alreadyDrawn[item][node] = true
                    end
                end
            end)
        end)
    end
end

local function drawSelectionRectangles(room)
    local previewBorderColor = colors.selectionPreviewBorderColor
    local previewFillColor = colors.selectionPreviewFillColor
    local completeBorderColor = colors.selectionCompleteBorderColor
    local completeFillColor = colors.selectionCompleteFillColor

    local lineWidth = love.graphics.getLineWidth()
    local drawnSelections = {}

    drawSelectionRectanglesCommon(room, selectionPreviews, previewBorderColor, previewFillColor, lineWidth, drawnSelections)
    drawSelectionRectanglesCommon(room, selectionTargets, completeBorderColor, completeFillColor, lineWidth, drawnSelections)
end

local function drawAxisBoundMovementLines(room)
    viewportHandler.drawRelativeTo(room.x, room.y, function()
        drawing.callKeepOriginalColor(function()
            local roomWidth, roomHeight = room.width, room.height
            local coverX, coverY, coverWidth, coverHeight = coverStartX, coverStartY, coverStartWidth, coverStartyHeight

            -- Make length slightly shorter to prevent overlapping at the selection area
            local lengthOffset = 1

            love.graphics.setColor(colors.selectionAxisBoundMovementLines)

            -- Draw from room borders towards selection
            -- Left
            if coverX >= 0 then
                drawing.drawDashedLine(0, coverY, coverX - lengthOffset, coverY)
                drawing.drawDashedLine(0, coverY + coverHeight, coverX - lengthOffset, coverY + coverHeight)
            end

            -- Right
            if coverX + coverWidth <= roomWidth then
                drawing.drawDashedLine(roomWidth, coverY, coverX + coverWidth + lengthOffset, coverY)
                drawing.drawDashedLine(roomWidth, coverY + coverHeight, coverX + coverWidth + lengthOffset, coverY + coverHeight)
            end

            -- Top
            if coverY >= 0 then
                drawing.drawDashedLine(coverX, 0, coverX, coverY - lengthOffset)
                drawing.drawDashedLine(coverX + coverWidth, 0, coverX + coverWidth, coverY - lengthOffset)
            end

            -- Bottom
            if coverY + coverHeight <= roomHeight then
                drawing.drawDashedLine(coverX, roomHeight, coverX, coverY + coverHeight + lengthOffset)
                drawing.drawDashedLine(coverX + coverWidth, roomHeight, coverX + coverWidth, coverY + coverHeight + lengthOffset)
            end
        end)
    end)
end

local function drawAxisBoundSelectionArea(room)
    if selectionPreviews then
        local fillColor = colors.selectionAxisBoundSelectionBackground

        local areaX, areaY, areaWidth, areaHeight = utils.coverRectangles(selectionPreviews)

        if #selectionPreviews > 1 then
            viewportHandler.drawRelativeTo(room.x, room.y, function()
                drawing.callKeepOriginalColor(function()
                    love.graphics.setColor(fillColor)

                    love.graphics.rectangle("fill", areaX, areaY, areaWidth, areaHeight)
                end)
            end)
        end
    end
end

local function drawAxisBoundMovement(room)
    if room and selectionPreviews and not resizeDirectionPreview and movementActive then
        local axisBound = keyboardHelper.modifierHeld(configs.editor.movementAxisBoundModifier)

        if axisBound then
            drawAxisBoundMovementLines(room)
            drawAxisBoundSelectionArea(room)
        end
    end
end

local function getMoveCallback(room, layer, targets, offsetX, offsetY, redrawInCallback)
    local backingMatrices = tiles.getBackingMatrices(targets)

    return function()
        local redraw = false

        tiles.beforeSelectionChanges(room, targets, backingMatrices)

        for _, item in ipairs(targets) do
            local moved = selectionItemUtils.moveSelection(room, layer, item, offsetX, offsetY)

            if moved then
                redraw = true
            end

            if redraw and redrawInCallback then
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end
        end

        return redraw
    end
end

local function getResizeCallback(room, layer, targets, offsetX, offsetY, directionX, directionY, redrawInCallback)
    return function()
        local redraw = false

        for _, item in ipairs(targets) do
            local resized = selectionItemUtils.resizeSelection(room, layer, item, offsetX, offsetY, directionX, directionY)

            if resized then
                redraw = true
            end

            if redraw and redrawInCallback then
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end
        end

        return redraw
    end
end

local function getRotationCallback(room, layer, targets, direction, redrawInCallback)
    local backingMatrices = tiles.getBackingMatrices(targets)

    return function()
        local redraw = false

        tiles.beforeSelectionChanges(room, targets, backingMatrices)

        for _, item in ipairs(targets) do
            local rotated = selectionItemUtils.rotateSelection(room, layer, item, direction)

            if rotated then
                redraw = true
            end
        end

        if redraw and redrawInCallback then
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end

        return redraw
    end
end

local function getAreaFlipCallback(room, layer, targets, horizontal, vertical, redrawInCallback)
    local backingMatrices = tiles.getBackingMatrices(targets)
    local targetArea = utils.rectangle(utils.coverRectangles(targets))

    return function()
        local redraw = false

        tiles.beforeSelectionChanges(room, targets, backingMatrices)

        for _, item in ipairs(targets) do
            local flipped = selectionItemUtils.areaFlipSelection(room, layer, item, horizontal, vertical, targetArea)

            if flipped then
                redraw = true
            end
        end

        if redraw and redrawInCallback then
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end

        return redraw
    end
end

local function getFlipCallback(room, layer, targets, horizontal, vertical, redrawInCallback)
    local backingMatrices = tiles.getBackingMatrices(targets)

    return function()
        local redraw = false

        tiles.beforeSelectionChanges(room, targets, backingMatrices)

        for _, item in ipairs(targets) do
            local flipped = selectionItemUtils.flipSelection(room, layer, item, horizontal, vertical)

            if flipped then
                redraw = true
            end
        end

        if redraw and redrawInCallback then
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end

        return redraw
    end
end

local function moveItems(room, layer, targets, offsetX, offsetY, callForward)
    local forward = getMoveCallback(room, layer, targets, offsetX, offsetY)
    local backward = getMoveCallback(room, layer, targets, -offsetX, -offsetY, true)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection moved", callForward)

    return snapshot, redraw
end

local function resizeItems(room, layer, targets, offsetX, offsetY, directionX, directionY, callForward)
    local forward = getResizeCallback(room, layer, targets, offsetX, offsetY, directionX, directionY)
    local backward = getResizeCallback(room, layer, targets, -offsetX, -offsetY, directionX, directionY, true)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized", callForward)

    return snapshot, redraw
end

local function rotateItems(room, layer, targets, direction, callForward)
    local forward = getRotationCallback(room, layer, targets, direction)
    local backward = getRotationCallback(room, layer, targets, -direction, true)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized", callForward)

    return snapshot, redraw
end

local function flipItems(room, layer, targets, horizontal, vertical, callForward)
    local forward = getFlipCallback(room, layer, targets, horizontal, vertical)
    local backward = getFlipCallback(room, layer, targets, horizontal, vertical, true)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized", callForward)

    return snapshot, redraw
end

local function areaFlipItems(room, layer, targets, horizontal, vertical, callForward)
    local forward = getAreaFlipCallback(room, layer, targets, horizontal, vertical)
    local backward = getAreaFlipCallback(room, layer, targets, horizontal, vertical, true)
    local snapshot, redraw = snapshotUtils.roomLayerRevertableSnapshot(forward, backward, room, layer, "Selection resized", callForward)

    return snapshot, redraw
end

local function deleteItems(room, layer, targets)
    local relevantLayers = selectionUtils.selectionTargetLayers(selectionTargets)
    local snapshot, redraw, selectionsBefore = snapshotUtils.roomLayersSnapshot(function()
        local redraw = false
        local selectionsBefore = utils.deepcopy(selectionTargets)

        for i = #targets, 1, -1 do
            local item = targets[i]
            local deleted = selectionItemUtils.deleteSelection(room, item.layer, item)

            if deleted then
                redraw = true

                table.remove(selectionTargets, i)
            end
        end

        return redraw, selectionsBefore
    end, room, relevantLayers, "Selection Deleted")

    return snapshot, redraw
end

local function getRelevantNodeAddSelections(layer, selections)
    -- If a entity/trigger has multiple selections
    -- Then we add the one with the highest node value
    local targetsBestNode = {}

    for _, selection in ipairs(selections) do
        local bestNode = targetsBestNode[selection.item] or 0

        if selection.node or bestNode < selection.node then
            targetsBestNode[selection.item] = selection.node
        end
    end

    local relevantSelections = {}

    for _, selection in ipairs(selections) do
        local bestNode = targetsBestNode[selection.item] or 0

        if selection.node == bestNode then
            table.insert(relevantSelections, selection)
        end
    end

    return relevantSelections
end

local function addNode(room, layer, targets)
    local relevantLayers = selectionUtils.selectionTargetLayers(selectionTargets)
    local snapshot, redraw, selectionsBefore = snapshotUtils.roomLayersSnapshot(function()
        local redraw = false
        local selectionsBefore = utils.deepcopy(selectionTargets)
        local newTargets = {}

        local relevantSelections = getRelevantNodeAddSelections(layer, targets)

        for _, selection in ipairs(relevantSelections) do
            local added = selectionItemUtils.addNodeToSelection(room, selection.layer, selection)

            if added then
                local item = selection.item
                local node = selection.node

                -- Make sure selection nodes for the target is correct
                for _, target in ipairs(targets) do
                    if target.item == item then
                        if target.node > node then
                            target.node += 1
                        end
                    end
                end

                -- Add new node to selections
                local rectangles = selectionUtils.getSelectionsForItem(room, selection.layer, item)

                -- Nodes are off by one here since the main entity would be the first rectangle
                -- We also insert after the target node, meaning the total offset is two
                local nodeRectangle = rectangles[node + 2]

                nodeRectangle.item = item
                nodeRectangle.node = node + 1

                table.insert(newTargets, nodeRectangle)

                redraw = true
            end
        end

        for _, newTarget in ipairs(newTargets) do
            table.insert(targets, newTarget)
        end

        return redraw, selectionsBefore
    end, room, relevantLayers, "Node Added")

    return snapshot, redraw
end

local function getSelectionTargetCorners(targets)
    local tlx, tly = math.huge, math.huge
    local brx, bry = -math.huge, -math.huge

    for _, target in ipairs(targets or selectionTargets) do
        tlx = math.min(tlx, target.x)
        tly = math.min(tly, target.y)

        brx = math.max(brx, target.x + target.width)
        bry = math.max(bry, target.y + target.height)
    end

    return tlx, tly, brx, bry
end

-- TODO - Improve decal logic, currently can't copy paste between bg <-> fg
local function pasteItems(room, layer, targets)
    local pasteCentered = configs.editor.pasteCentered
    local relevantLayers = selectionUtils.selectionTargetLayers(targets)
    local snapshot = snapshotUtils.roomLayersSnapshot(function()
        local layerItems = {}
        local newTargets = {}

        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(viewportHandler.getMousePosition())

        local tlx, tly, brx, bry = getSelectionTargetCorners(targets)
        local width, height = brx - tlx, bry - tly
        local widthOffset = pasteCentered and math.floor(width / 2) or 0
        local heightOffset = pasteCentered and math.floor(height / 2) or 0

        -- Make sure items that are already on the grid stay on it
        local offsetX, offsetY = cursorX - tlx - widthOffset, cursorY - tly - heightOffset
        local offsetGridX, offsetGridY = placementUtils.getGridPosition(offsetX, offsetY, false)

        for _, target in ipairs(targets) do
            local item = target.item
            local targetLayer = target.layer

            item.x += offsetGridX
            item.y += offsetGridY
            target.x += offsetGridX
            target.y += offsetGridY

            placementUtils.finalizePlacement(room, targetLayer, item)
            placementUtils.addSubLayer(item, targetLayer, tool.subLayer)

            if type(item.nodes) == "table" then
                for _, node in ipairs(item.nodes) do
                    node.x += offsetGridX
                    node.y += offsetGridY
                end
            end

            -- Add the new item to the correct layer
            -- Tiles handle this in the finalizePlacement call
            if not tiles.tileLayers[targetLayer] then
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

            -- Special case tile layer selections
            if tiles.tileLayers[targetLayer] then
                table.insert(newTargets, target)

            else
                -- Add preview for all main and node parts of the item
                -- Makes more sense for visuals after a paste
                selectionUtils.getSelectionsForItem(room, targetLayer, item, newTargets)
            end
        end

        tool.setSelectionTargets(newTargets)
        tiles.selectionsChanged(newTargets)

        return relevantLayers
    end, room, relevantLayers, "Selection Pasted")

    return snapshot, relevantLayers
end

local function handleItemMovementKeys(room, key, scancode, isrepeat)
    for _, movementData in ipairs(selectionMovementKeys) do
        local configKey, offsetX, offsetY = movementData[1], movementData[2], movementData[3]
        local targetKey = configs.editor[configKey]

        if not keyboardHelper.modifierHeld(configs.editor.precisionModifier) then
            offsetX *= 8
            offsetY *= 8
        end

        if targetKey == key then
            local snapshot, redraw = moveItems(room, tool.layer, selectionTargets, offsetX, offsetY)

            if redraw then
                history.addSnapshot(snapshot)
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end

            return true
        end
    end

    return false
end

local function handleItemResizeKeys(room, key, scancode, isrepeat)
    for _, resizeData in ipairs(selectionResizeKeys) do
        local configKey, offsetX, offsetY, directionX, directionY = resizeData[1], resizeData[2], resizeData[3], resizeData[4], resizeData[5]
        local targetKey = configs.editor[configKey]

        if not keyboardHelper.modifierHeld(configs.editor.precisionModifier) then
            offsetX *= 8
            offsetY *= 8
        end

        if targetKey == key then
            local snapshot, redraw = resizeItems(room, tool.layer, selectionTargets, offsetX, offsetY, directionX, directionY)

            if redraw then
                history.addSnapshot(snapshot)
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end

            return true
        end
    end

    return false
end

local function handleItemRotateKeys(room, key, scancode, isrepeat)
    for _, rotationData in ipairs(selectionRotationKeys) do
        local configKey, direction = rotationData[1], rotationData[2]
        local targetKey = configs.editor[configKey]

        if targetKey == key then
            local snapshot, redraw = rotateItems(room, tool.layer, selectionTargets, direction)

            if redraw then
                history.addSnapshot(snapshot)
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end

            return true
        end
    end

    return false
end

local function handleItemFlipKeys(room, key, scancode, isrepeat)
    for _, flipData in ipairs(selectionFlipKeys) do
        local configKey, horizontal, vertical = flipData[1], flipData[2], flipData[3]
        local targetKey = configs.editor[configKey]

        if targetKey == key then
            local snapshot, redraw = flipItems(room, tool.layer, selectionTargets, horizontal, vertical)

            if redraw then
                history.addSnapshot(snapshot)
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end

            return true
        end
    end

    return false
end

local function handleItemDeletionKey(room, key, scancode, isrepeat)
    local targetKey = configs.editor.itemDelete

    if targetKey == key then
        local relevantLayers = selectionUtils.selectionTargetLayers(selectionTargets)
        local snapshot, redraw = deleteItems(room, tool.layer, selectionTargets)

        if redraw then
            history.addSnapshot(snapshot)
            toolUtils.redrawTargetLayer(room, relevantLayers)
        end

        return true
    end

    return false
end

local function handleNodeAddKey(room, key, scancode, isrepeat)
    local targetKey = configs.editor.itemAddNode

    if targetKey == key and not isrepeat then
        local snapshot, redraw = addNode(room, tool.layer, selectionTargets)

        if redraw then
            history.addSnapshot(snapshot)
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end

        return true
    end

    return false
end

-- Clean up some redundant data for the clipboard
-- Remove type data and simplify nodes
local function prepareCopyForClipboard(targets)
    local items = {}

    for _, target in ipairs(targets) do
        local item = target.item
        local nodes = item.nodes

        if nodes then
            nodes._type = nil

            for _, node in ipairs(nodes) do
                node._type = nil
            end
        end

        if tiles.tileLayers[target.layer] then
            tiles.clipboardPrepareCopy(target)
        end

        target.item._fromLayer = target.layer

        table.insert(items, target.item)
    end

    return items
end

local function rebuildSelectionFromItem(room, item)
    -- We only need the first rectangle, pasting sets up the rest
    local layer = item._fromLayer
    local rectangles = selectionUtils.getSelectionsForItem(room, layer, item)
    local rectangle = rectangles[1]

    if tiles.tileLayers[layer] then
        rectangle, item = tiles.rebuildSelection(room, item)
    end

    rectangle.layer = layer
    item._fromLayer = nil
    rectangle.item = item

    local nodes = item.nodes

    if nodes then
        nodes._type = nodeStruct.nodesType

        for _, node in ipairs(nodes) do
            node._type = nodeStruct.nodeType
        end
    end

    return rectangle
end

-- Add back some of the data we need for pasting that can be infered
local function preparePasteFromClipboard(room, items)
    local targets = {}

    for _, item in ipairs(items) do
        if utils.typeof(item) == "rectangle" then
            table.insert(targets, item)

        else
            local target = rebuildSelectionFromItem(room, item)

            table.insert(targets, target)
        end
    end

    return targets
end

local function copyCommon(cut)
    local room = state.getSelectedRoom()
    local useClipboard = configs.editor.copyUsesClipboard

    if not room or not selectionTargets or #selectionTargets == 0 then
        return false
    end

    copyTargets = {}

    -- We should only handle an item once
    local handledItems = {}

    for _, target in ipairs(selectionTargets) do
        local item = target.item

        if not handledItems[item] then
            local targetCopy = utils.deepcopy(target)

            targetCopy.node = 0
            handledItems[item] = true

            table.insert(copyTargets, targetCopy)
        end
    end

    if cut then
        local relevantLayers = selectionUtils.selectionTargetLayers(selectionTargets)
        local snapshot, redraw = deleteItems(room, tool.layer, selectionTargets)

        if redraw then
            history.addSnapshot(snapshot)
            toolUtils.redrawTargetLayer(room, relevantLayers)
        end
    end

    if useClipboard then
        local success, text = utils.serialize(prepareCopyForClipboard(copyTargets))

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
    local newTargets = utils.deepcopy(copyTargets)

    local room = state.getSelectedRoom()

    if not room then
        return
    end

    if useClipboard then
        local clipboard = love.system.getClipboardText()

        if validateClipboard(clipboard) then
            local success, fromClipboard = utils.unserialize(clipboard, true, 3)

            if success then
                newTargets = preparePasteFromClipboard(room, fromClipboard)
            end
        end
    end

    if newTargets and #newTargets > 0 then
        local snapshot, usedLayers = pasteItems(room, tool.layer, newTargets)

        history.addSnapshot(snapshot)
        selectionUtils.redrawTargetLayers(room, selectionTargets)

        toolUtils.redrawTargetLayer(room, usedLayers)
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

local function updateSelectionTargets(x, y)
    if selectionTargets then
        local couldResize = #selectionTargets > 0

        if couldResize then
             -- TODO - Put sensitivity in config?

            resizeDirectionPreview = nil

            local room = state.getSelectedRoom()
            local viewport = viewportHandler.viewport
            local cameraZoom = viewport.scale
            local borderThreshold = 4 / cameraZoom

            local point = utils.point(x, y)

            -- Find first selection where we are on the border
            for _, preview in ipairs(selectionTargets) do
                local mainTarget = preview.node == 0

                if mainTarget then
                    local resizeHorizontal, resizeVertical = selectionItemUtils.canResizeItem(room, tool.layer, preview)
                    local onBorder, horizontalDirection, verticalDirection = utils.onRectangleBorder(point, preview, borderThreshold)

                    if not resizeHorizontal then
                        horizontalDirection = 0
                    end

                    if not resizeVertical then
                        verticalDirection = 0
                    end

                    if onBorder and (horizontalDirection ~= 0 or verticalDirection ~= 0) and preview.node == 0 then
                        resizeDirectionPreview = {horizontalDirection, verticalDirection}

                        break
                    end
                end
            end
        end
    end
end

local function updateSelectionTargetsFromPreviews(keepExisting)
    if keepExisting then
        -- Make sure we have no duplicates
        local existingTargets = {}

        for _, target in ipairs(selectionTargets) do
            existingTargets[target.item] = existingTargets[target.item] or {}
            existingTargets[target.item][target.node] = true
        end

        for _, preview in ipairs(selectionPreviews) do
            local existing = existingTargets[preview.item]

            if not existing or not existing[preview.node] then
                table.insert(selectionTargets, preview)
            end
        end

    else
        tool.setSelectionTargets(selectionPreviews)
    end
end

local function selectionStarted(x, y)
    selectionRectangle = utils.rectangle(x, y, 0, 0)
    tool.setSelectionPreviews({})
    selectionCompleted = false
    resizeDirection = nil
    resizeDirectionPreview = nil

    dragStartX = x
    dragStartY = y
end

local function selectionFinished(x, y, fromClick)
    local addModifier = keyboardHelper.modifierHeld(configs.editor.selectionAddModifier)

    selectionRectangle = false
    selectionCompleted = true

    local doingMouseActions = movementActive or resizeDirection

    -- Special case, otherwise we lose some selections
    if not fromClick and not doingMouseActions then
        updateSelectionTargetsFromPreviews(addModifier)
        tiles.selectionsChanged(selectionTargets)

        tool.setSelectionPreviews({})
    end
end

local function resizeStarted(x, y)
    dragStartX = x
    dragStartY = y
end

local function resizeFinished(x, y)
    local hasResizeDelta = resizeLastOffsetX and resizeLastOffsetY and (resizeLastOffsetX ~= 0 or resizeLastOffsetY ~= 0)

    if selectionTargets and #selectionTargets > 0 and resizeDirection and hasResizeDelta then
        local room = state.getSelectedRoom()
        local directionX, directionY = unpack(resizeDirection)
        local deltaX, deltaY = resizeLastOffsetX, resizeLastOffsetY
        local offsetX, offsetY = deltaX * directionX, deltaY * directionY

        -- Don't call forward function, we have already resized the items
        local snapshot, redraw = resizeItems(room, tool.layer, selectionTargets, offsetX, offsetY, directionX, directionY, false)

        if snapshot then
            history.addSnapshot(snapshot)
        end

        if redraw then
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end
    end

    resizeDirection = nil
    resizeDirectionPreview = nil
    resizeLastOffsetX = nil
    resizeLastOffsetY = nil

    updateSelectionTargets(x, y)
end

local function movementStarted(x, y)
    dragStartX = x
    dragStartY = y

    coverStartX, coverStartY, coverStartWidth, coverStartyHeight = utils.coverRectangles(selectionTargets)
    dragMovementTotalX, dragMovementTotalY = 0, 0
end

local function movementFinished(x, y)
    local hasMovementDelta = dragMovementTotalX and dragMovementTotalY and (dragMovementTotalX ~= 0 or dragMovementTotalY ~= 0)

    if selectionTargets and #selectionTargets > 0 and hasMovementDelta then
        -- Don't call forward function, we have already moved the items
        local room = state.getSelectedRoom()
        local snapshot, redraw = moveItems(room, tool.layer, selectionTargets, dragMovementTotalX, dragMovementTotalY, false)

        if snapshot then
            history.addSnapshot(snapshot)
        end

        if redraw then
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end
    end

    movementActive = false
    movementLastOffsetX = nil
    movementLastOffsetY = nil

    dragMovementTotalX, dragMovementTotalY = 0, 0
end

local function getSimilarSelections(targetSelection, strict)
    local room = state.getSelectedRoom()
    local rectangle = utils.rectangle(-math.huge, -math.huge, math.huge, math.huge)
    local allSelections = selectionUtils.getSelectionsForRoomInRectangle(room, tool.layer, tool.subLayer, rectangle)
    local result = {}

    for _, selection in ipairs(allSelections) do
        if selectionItemUtils.selectionsSimilar(targetSelection, selection, strict) then
            table.insert(result, selection)
        end
    end

    return result
end

local function selectSimilar(strict)
    local target = selectionTargets[1]

    if not target then
        return false
    end

    local similarSelections = getSimilarSelections(target, strict)

    tool.setSelectionPreviews({})
    tool.setSelectionTargets(similarSelections)
end

local function selectAllHotkey()
    -- Fake a infinitely large selection
    local x, y = -math.huge, -math.huge
    local width, height = math.huge, math.huge

    selectionChanged(x, y, width, height)

    selectionFinished(x, y)
    resizeFinished(x, y)
    movementFinished(x, y)
end

local function deselectHotkey()
    tool.setSelectionPreviews({})
    tool.setSelectionTargets({})
end

local function areaFlipHotkeyCommon(horizontal, vertical)
    return function()
        local room = state.getSelectedRoom()
        local snapshot, redraw = areaFlipItems(room, tool.layer, selectionTargets, horizontal, vertical)

        if redraw then
            history.addSnapshot(snapshot)
            selectionUtils.redrawTargetLayers(room, selectionTargets)
        end
    end
end

-- Modifier keys that update behavior/visuals
local behaviorUpdatingModifiersKey = {
    configs.editor.precisionModifier,
    configs.editor.movementAxisBoundModifier
}

local behaviorUpdatingModifiersKeyState = {}

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

            local snapshot, redraw = resizeItems(room, tool.layer, selectionTargets, deltaX * directionX, deltaY * directionY, directionX, directionY)

            if redraw then
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end
        end
    end
end

local function mouseMovedMovement(cursorX, cursorY)
    local room = state.getSelectedRoom()

    if room and cursorX and cursorY and dragStartX and dragStartY then
        local precise = keyboardHelper.modifierHeld(configs.editor.precisionModifier)
        local axisBound = keyboardHelper.modifierHeld(configs.editor.movementAxisBoundModifier)
        local startX, startY = dragStartX, dragStartY

        if not precise then
            cursorX = utils.round(cursorX / 8) * 8
            cursorY = utils.round(cursorY / 8) * 8

            startX = utils.round(startX / 8) * 8
            startY = utils.round(startY / 8) * 8
        end

        local deltaX = cursorX - (movementLastOffsetX or cursorX)
        local deltaY = cursorY - (movementLastOffsetY or cursorY)

        if axisBound then
            local fullDeltaX = (cursorX - startX)
            local fullDeltaY = (cursorY - startY)

            if math.abs(fullDeltaX) >= math.abs(fullDeltaY) then
                deltaY = -dragMovementTotalY
                movementLastOffsetX = cursorX
                movementLastOffsetY = startY

            else
                deltaX = -dragMovementTotalX
                movementLastOffsetX = startX
                movementLastOffsetY = cursorY
            end

        else
            movementLastOffsetX = cursorX
            movementLastOffsetY = cursorY
        end

        dragMovementTotalX += deltaX
        dragMovementTotalY += deltaY

        if deltaX ~= 0 or deltaY ~= 0 then
            local snapshot, redraw = moveItems(room, tool.layer, selectionTargets, deltaX, deltaY)

            if redraw then
                selectionUtils.redrawTargetLayers(room, selectionTargets)
            end
        end
    end
end

local function behaviorModifiersChanged()
    local result = false

    for _, modifier in ipairs(behaviorUpdatingModifiersKey) do
        local held = keyboardHelper.modifierHeld(modifier)

        if held ~= behaviorUpdatingModifiersKeyState[modifier] then
            result = true
            behaviorUpdatingModifiersKeyState[modifier] = held
        end
    end

    return result
end

local function updateVisualsOnBehaviorChange()
    if behaviorModifiersChanged() then
        local x, y = viewportHandler.getMousePosition()

        -- Send mousemoved event to update visuals
        -- Using delta of (0, 0) to cause no actual change
        tool.mousemoved(x, y, 0, 0, false)
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton
    local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

    if cursorX and cursorY then
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
            updateSelectionTargets(cursorX, cursorY)
        end
    end

    updateCursor()
end

function tool.mousereleased(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY then
            selectionFinished(cursorX, cursorY)
            resizeFinished(cursorX, cursorY)
            movementFinished(cursorX, cursorY)
        end
    end

    updateCursor()
end

-- Special case
function tool.mouseclicked(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton
    local contextMenuButton = configs.editor.contextMenuButton

    if button == actionButton then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY then
            local addSelections = keyboardHelper.modifierHeld(configs.editor.selectionAddModifier)

            if addSelections and presses % 2 == 0 then
                local strict = keyboardHelper.modifierHeld(configs.editor.precisionModifier)

                selectSimilar(strict)

            else
                selectionChanged(cursorX - 1, cursorY - 1, 3, 3, true)

                selectionFinished(cursorX, cursorY, true)
                resizeFinished(cursorX, cursorY)
                movementFinished(cursorX, cursorY)
            end
        end

    elseif button == contextMenuButton then
        local cursorX, cursorY = toolUtils.getCursorPositionInRoom(x, y)

        if cursorX and cursorY then
            local room = state.getSelectedRoom()
            local contextSelections, bestTarget = selectionUtils.getContextSelections(room, tool.layer, room.subLayer, cursorX, cursorY, selectionTargets)

            selectionUtils.sendContextMenuEvent(contextSelections, bestTarget, room)
        end
    end
end

function tool.keyreleased(key, scancode)
    updateVisualsOnBehaviorChange()
end

function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()
    local handled = false

    updateVisualsOnBehaviorChange()

    if selectionTargets and room then
        handled = handled or handleItemMovementKeys(room, key, scancode, isrepeat)
        handled = handled or handleItemResizeKeys(room, key, scancode, isrepeat)
        handled = handled or handleItemRotateKeys(room, key, scancode, isrepeat)
        handled = handled or handleItemFlipKeys(room, key, scancode, isrepeat)
        handled = handled or handleItemDeletionKey(room, key, scancode, isrepeat)
        handled = handled or handleNodeAddKey(room, key, scancode, isrepeat)
    end

    return handled
end

function tool.editorMapLoaded(item, itemType)
    tool.setSelectionTargets({})
    tool.setSelectionPreviews({})
end

function tool.editorMapTargetChanged(item, itemType)
    tool.setSelectionTargets({})
    tool.setSelectionPreviews({})
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        drawSelectionArea(room)

        -- TODO - Improve this?
        -- Draw only border in axis drag mode?
        -- Draw no selection rectangles in axis drag mode?
        if movementActive and not resizeDirection and keyboardHelper.modifierHeld(configs.editor.movementAxisBoundModifier) then
            drawAxisBoundMovement(room)

        else
            drawItemSelections(room)
            drawSelectionRectangles(room)
        end
    end
end

local function addHotkeys()
    local hotkeyScope = string.format("tools.%s", tool.name)

    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemAreaFlipHorizontal, areaFlipHotkeyCommon(true, false))
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemAreaFlipVertical, areaFlipHotkeyCommon(false, true))
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsCopy, copyItemsHotkey)
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsPaste, pasteItemsHotkey)
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsCut, cutItemsHotkey)
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsSelectAll, selectAllHotkey)
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsDeselect, deselectHotkey)
end

function tool.load()
    tool.setSelectionTargets({})
    tool.setSelectionPreviews({})

    addHotkeys()
end

function tool.unselect()
    tool.setSelectionTargets({})
    tool.setSelectionPreviews({})
end

return tool
