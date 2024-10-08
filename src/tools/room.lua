local state = require("loaded_state")
local configs = require("configs")
local drawing = require("utils.drawing")
local utils = require("utils")
local viewportHandler = require("viewport_handler")
local rectangleStruct = require("structs.rectangle")
local colors = require("consts.colors")
local keyboardHelper = require("utils.keyboard")
local mapItemUtils = require("map_item_utils")
local sceneHandler = require("scene_handler")
local hotkeyHandler = require("hotkey_handler")
local celesteRender = require("celeste_render")
local roomStruct = require("structs.room")

local tool = {}

tool._type = "tool"
tool.name = "room"
tool.group = "room"
tool.image = nil
tool.manualRoomLogic = true

tool.validLayers = {}

tool.mode = "selection"
tool.modes = {
    "placement",
    "selection",
}

local movementDrag = false
local selectionDrag = false
local placementDrag = false

local dragStartX
local dragStartY
local dragMovementTotalX = 0
local dragMovementTotalY = 0
local lastMoveX
local lastMoveY

-- Initial cover of selections
local coverX, coverY, coverWidth, coverHeight

local selectionRectangle
local selectionPreviews

local selectionMovementKeys = {
    {"itemMoveLeft", "left"},
    {"itemMoveRight", "right"},
    {"itemMoveUp", "up"},
    {"itemMoveDown", "down"},
}

local function rectangleInRoom(rectangle, room)
    return utils.aabbCheck(room, rectangle)
end

local function rectangleInFiller(rectangle, filler)
    local fillerRectangle = rectangleStruct.create(filler.x * 8, filler.y * 8, filler.width * 8, filler.height * 8)

    return utils.aabbCheck(fillerRectangle, rectangle)
end

local function mapItemsInRectangle(rectangle)
    local map = state.map
    local result = {}

    if not map then
        return {}
    end

    for _, room in ipairs(map.rooms) do
        if rectangleInRoom(rectangle, room) then
            result[room] = true
        end
    end

    for _, filler in ipairs(map.fillers) do
        if rectangleInFiller(rectangle, filler) then
            result[filler] = true
        end
    end

    return result
end

local function hoveringSelection(mapX, mapY)
    local cursorRectangle = rectangleStruct.create(mapX, mapY, 1, 1)
    local selections = mapItemsInRectangle(cursorRectangle)

    local selectedItem = state.getSelectedItem()

    if selections[selectedItem] then
        return selectedItem
    end

    if type(selectedItem) == "table" then
        for item, _ in pairs(selectedItem) do
            if selections[item] then
                return item
            end
        end
    end

    return false
end

local function hoveringMapItem(mapX, mapY)
    local cursorRectangle = rectangleStruct.create(mapX, mapY, 1, 1)
    local selections = mapItemsInRectangle(cursorRectangle)

    for k, _ in pairs(selections) do
        return k
    end

end

local function getFakeRoomPositionSize()
    if not lastMoveX or not lastMoveY then
        return 0, 0, 0, 0
    end

    local dragStartTileX, dragStartTileY = viewportHandler.pixelToTileCoordinates(dragStartX, dragStartY)
    local lastMoveTileX, lastMoveTileY = viewportHandler.pixelToTileCoordinates(lastMoveX, lastMoveY)

    local x = math.min(dragStartTileX, lastMoveTileX) * 8
    local y = math.min(dragStartTileY, lastMoveTileY) * 8

    local width = math.abs(dragStartTileX - lastMoveTileX) * 8 + 8
    local height = math.abs(dragStartTileY - lastMoveTileY) * 8 + 8

    return x, y, width, height
end

-- Always return as a set
local function getSelectionTargets()
    local selectionTargets = state.getSelectedItem()

    if selectionTargets and utils.typeof(selectionTargets) ~= "table" then
        local selectedItem = selectionTargets

        selectionTargets = {}
        selectionTargets[selectedItem] = true
    end

    return selectionTargets or {}
end

local function getSelectionCover()
    local selectionTargets = getSelectionTargets()
    local rectangles = {}

    for item, _ in pairs(selectionTargets) do
        local x, y = item.x, item.y
        local width, height = item.width, item.height

        -- Fillers are stored in tiles
        if utils.typeof(item) == "filler" then
            x *= 8
            y *= 8

            width *= 8
            height *= 8
        end

        table.insert(rectangles, rectangleStruct.create(x, y, width, height))
    end

    local x, y, width, height = utils.coverRectangles(rectangles)
    local viewportScale = viewportHandler.viewport.scale
    local windowX, windowY = viewportHandler.getWindowCoordinates(x, y)
    local windowWidth, windowHeight = width * viewportScale, height * viewportScale

    return windowX, windowY, windowWidth, windowHeight
end

local function selectionFinished()
    if selectionDrag then
        selectionPreviews = mapItemsInRectangle(selectionRectangle)

        local addModifier = keyboardHelper.modifierHeld(configs.editor.selectionAddModifier)

        if not addModifier then
            state.selectItem()
        end

        for item, _ in pairs(selectionPreviews or {}) do
            state.selectItem(item, true)
        end
    end

    if movementDrag then
        -- Manually handle snapshots
        if dragMovementTotalX ~= 0 or dragMovementTotalY ~= 0 then
            -- Move back without history, then move back again with history

            local selectedItem = state.getSelectedItem()

            mapItemUtils.move(selectedItem, -dragMovementTotalX, -dragMovementTotalY, 8, false)
            mapItemUtils.move(selectedItem, dragMovementTotalX, dragMovementTotalY, 8, true)

            coverX, coverY, coverWidth, coverHeight = nil, nil, nil, nil
        end
    end

    if placementDrag then
        local fakeRoom = roomStruct.decode({})
        local selectedRoom = state.getSelectedRoom()

        if selectedRoom then
            for k, v in pairs(selectedRoom) do
                -- Copy any simple value over, not tiles etc
                if type(v) ~= "table" then
                    fakeRoom[k] = v
                end
            end
        end

        -- Overwrite with what the user inputted
        fakeRoom.x, fakeRoom.y, fakeRoom.width, fakeRoom.height = getFakeRoomPositionSize()

        if fakeRoom.width > 0 and fakeRoom.height > 0 then
            sceneHandler.sendEvent("editorRoomAdd", state.map, fakeRoom)
        end
    end

    dragStartX = nil
    dragStartY = nil
    lastMoveX = nil
    lastMoveY = nil
    dragMovementTotalX = 0
    dragMovementTotalY = 0

    movementDrag = false
    selectionDrag = false
    placementDrag = false

    selectionPreviews = nil
    selectionRectangle = nil
end

function tool.mouseclicked(x, y, button, istouch, pressed)
    local actionButton = configs.editor.actionButton
    local contextMenuButton = configs.editor.contextMenuButton

    if button == actionButton then
        selectionFinished()

    elseif button == contextMenuButton then
        local map = state.map
        local mapX, mapY = viewportHandler.getMapCoordinates(x, y)
        local hovering = hoveringMapItem(mapX, mapY)

        if map and hovering and utils.typeof(hovering) == "room" then
            sceneHandler.sendEvent("editorRoomConfigure", map, hovering)
        end
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton
    local axisBound = keyboardHelper.modifierHeld(configs.editor.movementAxisBoundModifier)

    -- Check if button is held, tool handler might consume mouse up to change room
    if love.mouse.isDown(actionButton) then
        if selectionDrag then
            local mapX, mapY = viewportHandler.getMapCoordinates(x, y)
            local width, height = mapX - dragStartX, mapY - dragStartY

            selectionRectangle = rectangleStruct.create(dragStartX, dragStartY, width, height)
            selectionPreviews = mapItemsInRectangle(selectionRectangle)
        end

        if movementDrag then
            local mapX, mapY = viewportHandler.getMapCoordinates(x, y)

            lastMoveX = lastMoveX or mapX
            lastMoveY = lastMoveY or mapY

            local deltaX = mapX - lastMoveX
            local deltaY = mapY - lastMoveY

            if axisBound then
                local totalDeltaX = mapX - dragStartX
                local totalDeltaY = mapY - dragStartY

                if math.abs(totalDeltaX) > math.abs(totalDeltaY) then
                    deltaY = -dragMovementTotalY * 8
                    lastMoveY = dragStartY

                else
                    deltaX = -dragMovementTotalX * 8
                    lastMoveX = dragStartX
                end
            end

            -- Floor towards zero
            local moveTilesX = math.floor(math.abs(deltaX) / 8) * utils.sign(deltaX)
            local moveTilesY = math.floor(math.abs(deltaY) / 8) * utils.sign(deltaY)

            local selectionItem = state.getSelectedItem()

            if moveTilesX ~= 0 or moveTilesY ~= 0 then
                mapItemUtils.move(selectionItem, moveTilesX, moveTilesY, 8, false)
            end

            if moveTilesX ~= 0 then
                lastMoveX = mapX
                dragMovementTotalX += moveTilesX
            end

            if moveTilesY ~= 0 then
                lastMoveY = mapY
                dragMovementTotalY += moveTilesY
            end
        end

        if placementDrag then
            local mapX, mapY = viewportHandler.getMapCoordinates(x, y)

            lastMoveX = mapX
            lastMoveY = mapY
        end
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local mapX, mapY = viewportHandler.getMapCoordinates(x, y)
        local selectionHovered = hoveringSelection(mapX, mapY)
        local mapItemHovered = hoveringMapItem(mapX, mapY)

        local placementMode = tool.mode == "placement"

        if placementMode then
            placementDrag = not mapItemHovered

            if not placementDrag and selectionHovered then
                movementDrag = true
            end

        else
            movementDrag = not not selectionHovered
            selectionDrag = not selectionHovered
        end

        if movementDrag then
            coverX, coverY, coverWidth, coverHeight = getSelectionCover()
        end

        dragStartX = mapX
        dragStartY = mapY

        selectionRectangle = rectangleStruct.create(mapX, mapY, 1, 1)
    end
end

function tool.mousereleased(x, y, button, istouch, presses, click)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        -- Update selection if we click in placement mode
        if click and tool.mode == "placement" then
            local mapX, mapY = viewportHandler.getMapCoordinates(x, y)

            selectionRectangle = rectangleStruct.create(mapX, mapY, 1, 1)
            selectionDrag = true
            placementDrag = false
        end

        selectionFinished()
    end
end

function tool.keypressed(key, scancode, isrepeat)
    for _, movementData in ipairs(selectionMovementKeys) do
        local configKey, direction = movementData[1], movementData[2]
        local targetKey = configs.editor[configKey]

        if targetKey == key then
            local selectionItem = state.getSelectedItem()

            mapItemUtils.directionalMove(selectionItem, direction, 1)
        end
    end

    local deleteKey = configs.editor.itemDelete

    if key == deleteKey then
        mapItemUtils.deleteItem(state.map, state.getSelectedItem())
    end
end

local function drawSelectionArea()
    if selectionRectangle and selectionDrag then
        -- Don't render if selection rectangle is too small, weird visuals
        if selectionRectangle.width >= 1 and selectionRectangle.height >= 1 then
            viewportHandler.drawRelativeTo(0, 0, function()
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

local function drawSelectionRectanglesCommon(targets, borderColor, fillColor, lineWidth, alreadyDrawn)
    alreadyDrawn = alreadyDrawn or {}

    if targets then
        -- Don't render if selection rectangle is too small, weird visuals
        -- TODO - See if we can use sprite batches here
        viewportHandler.drawRelativeTo(0, 0, function()
            drawing.callKeepOriginalColor(function()
                for item, _ in pairs(targets) do
                    if not alreadyDrawn[item] then
                        local x, y = item.x, item.y
                        local width, height = item.width, item.height

                        -- Fillers are stored in tiles
                        if utils.typeof(item) == "filler" then
                            x *= 8
                            y *= 8

                            width *= 8
                            height *= 8
                        end

                        love.graphics.setColor(fillColor)
                        love.graphics.rectangle("fill", x, y, width, height)

                        love.graphics.setColor(borderColor)
                        love.graphics.rectangle("line", x - lineWidth / 2, y - lineWidth / 2, width + lineWidth, height + lineWidth)

                        alreadyDrawn[item] = true
                    end
                end
            end)
        end)
    end
end

local function drawSelectionRectangles()
    local previewBorderColor = colors.selectionPreviewBorderColor
    local previewFillColor = colors.selectionPreviewFillColor
    local completeBorderColor = colors.selectionCompleteBorderColor
    local completeFillColor = colors.selectionCompleteFillColor

    local lineWidth = love.graphics.getLineWidth()
    local drawnSelections = {}

    local selectionTargets = getSelectionTargets()

    drawSelectionRectanglesCommon(selectionPreviews, previewBorderColor, previewFillColor, lineWidth, drawnSelections)
    drawSelectionRectanglesCommon(selectionTargets, completeBorderColor, completeFillColor, lineWidth, drawnSelections)
end

local function drawRoomPlacementPreview()
    if not lastMoveX or not lastMoveY then
        return
    end

    -- Try to match border/background color of current selected room
    local room = state.getSelectedRoom()

    local borderColor = colors.roomBorderDefault
    local backgroundColor = colors.roomBackgroundDefault

    if room then
        borderColor = celesteRender.getRoomBorderColor(room, true, state)
        backgroundColor = celesteRender.getRoomBackgroundColor(room, true, state)
    end

    local x, y, width, height = getFakeRoomPositionSize()

    viewportHandler.drawRelativeTo(0, 0, function()
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(backgroundColor)
            love.graphics.rectangle("fill", x, y, width, height)

            love.graphics.setColor(borderColor)
            love.graphics.rectangle("line", x, y, width, height)
        end)
    end)
end

local function drawAxisBoundMovementLines()
    drawing.callKeepOriginalColor(function()
        local windowWidth, windowHeight = love.graphics.getDimensions()

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
        if coverX + coverWidth <= windowWidth then
            drawing.drawDashedLine(windowWidth, coverY, coverX + coverWidth + lengthOffset, coverY)
            drawing.drawDashedLine(windowWidth, coverY + coverHeight, coverX + coverWidth + lengthOffset, coverY + coverHeight)
        end

        -- Top
        if coverY >= 0 then
            drawing.drawDashedLine(coverX, 0, coverX, coverY - lengthOffset)
            drawing.drawDashedLine(coverX + coverWidth, 0, coverX + coverWidth, coverY - lengthOffset)
        end

        -- Bottom
        if coverY + coverHeight <= windowHeight then
            drawing.drawDashedLine(coverX, windowHeight, coverX, coverY + coverHeight + lengthOffset)
            drawing.drawDashedLine(coverX + coverWidth, windowHeight, coverX + coverWidth, coverY + coverHeight + lengthOffset)
        end
    end)
end

local function selectAllHotkey()
    -- Fake a infinitely large selection
    selectionDrag = true
    selectionRectangle = rectangleStruct.create(-math.huge, -math.huge, math.huge, math.huge)

    selectionFinished()
end

local function deselectHotkey()
    state.selectItem()
end

function tool.draw()
    if movementDrag or selectionDrag or tool.mode == "selection" then
        local axisBound = keyboardHelper.modifierHeld(configs.editor.movementAxisBoundModifier)

        if axisBound and movementDrag then
            drawAxisBoundMovementLines()

        else
            drawSelectionArea()
            drawSelectionRectangles()
        end

    elseif placementDrag then
        drawRoomPlacementPreview()
    end
end

function tool.load()
    local hotkeyScope = string.format("tools.%s", tool.name)

    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsSelectAll, selectAllHotkey)
    hotkeyHandler.addHotkey(hotkeyScope, configs.hotkeys.itemsDeselect, deselectHotkey)
end

return tool
