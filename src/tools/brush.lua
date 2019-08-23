-- TODO
-- Consider making the "cursor" rectangle display the tile and how it would connect
-- Track placed tiles from press -> release for undo purposes

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local fonts = require("fonts")
local matrixLib = require("matrix")
local celesteRender = require("celeste_render")
local configs = require("configs")

local actionButton = configs.editor.toolActionButton
local cloneButton = configs.editor.objectCloneButton

local tool = {}

tool._type = "tool"
tool.name = "Brush"
tool.image = nil

tool.layer = "tilesFg"
tool.material = "a"

local lastTileX, lastTileY = -1, -1
local lastX, lastY = -1, -1

local previewMatrix = matrixLib.filled("0", 5, 5)
local previewBatch = nil

-- Attempts to place tile at x, y
-- Returns true if successful
local function placeTile(room, x, y, material, layer)
    local tiles = room[layer]
    local matrix = tiles.matrix

    matrix:set(x, y, material)

    return matrix:inbounds(x, y)
end

local function getTile(room, x, y, layer)
    local tiles = room[layer]
    local matrix = tiles.matrix

    return matrix:get(x, y)
end

local function handleActionClick(x, y, force)
    local room = state.selectedRoom

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if lastTileX ~= tx + 1 or lastTileY ~= ty + 1 or force then
            if placeTile(room, tx + 1, ty + 1, tool.material, tool.layer) then
                -- TODO - Redraw more efficiently
                celesteRender.invalidateRoomCache(room, tool.layer)
                celesteRender.invalidateRoomCache(room, "complete")
                celesteRender.forceRoomBatchRender(room, viewportHandler.viewport)
            end

            lastTileX, lastTileY = tx + 1, ty + 1
        end

        lastX, lastY = x, y
    end
end

local function handleCloneClick(x, y)
    local room = state.selectedRoom

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local material = getTile(room, tx + 1, ty + 1, tool.layer)

        if material then
            tool.material = material
        end
    end
end

function tool.mousepressed(x, y, button, istouch, pressed)
    if button == actionButton then
        handleActionClick(x, y)

    elseif button == cloneButton then
        handleCloneClick(x, y)
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    if love.mouse.isDown(actionButton) then
        handleActionClick(x, y)
    end
end

function tool.draw()
    local room = state.selectedRoom

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local hudText = string.format("Cursor: %s, %s (%s, %s)", tx + 1, ty + 1, px, py)

        love.graphics.printf(hudText, 20, 120, viewportHandler.viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)

        viewportHandler.drawRelativeTo(room.x, room.y, function()
            love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            love.graphics.rectangle("line", tx * 8, ty * 8, 8, 8)
        end)
    end
end


return tool