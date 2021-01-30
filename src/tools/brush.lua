-- TODO
-- Consider making the "cursor" rectangle display the tile and how it would connect
-- Track placed tiles from press -> release for undo purposes

local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local fonts = require("fonts")
local matrixLib = require("matrix")
local configs = require("configs")
local brushHelper = require("brush_helper")
local colors = require("colors")
local drawing = require("drawing")
local utils = require("utils")

local tool = {}

tool._type = "tool"
tool.name = "brush"
tool.group = "brush"
tool.image = nil

tool.layer = "tilesFg"
tool.validLayers = {
    "tilesFg",
    "tilesBg"
}

tool.material = "a"
tool.materialsLookup = {}

local lastTileX, lastTileY = -1, -1
local lastX, lastY = -1, -1

local previewMatrix = matrixLib.filled("0", 5, 5)
local previewBatch = nil

local function handleActionClick(x, y, force)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if lastTileX ~= tx + 1 or lastTileY ~= ty + 1 or force then
            brushHelper.placeTile(room, tx + 1, ty + 1, tool.material, tool.layer)

            lastTileX, lastTileY = tx + 1, ty + 1
        end

        lastX, lastY = x, y
    end
end

local function handleCloneClick(x, y)
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local material = brushHelper.getTile(room, tx + 1, ty + 1, tool.layer)

        if material then
            tool.material = material
        end
    end
end

local function cleanupMaterialPath(path)
    -- Remove tileset/ from front and humanize

    path = path:match("^tilesets/(.*)") or path

    if tool.layer == "tilesBg" then
        path = path:match("^bg(.*)") or path
    end

    return utils.humanizeVariableName(path)
end

local function updateMaterialLookup()
    tool.materialsLookup = {}

    local paths = brushHelper.getValidTiles(tool.layer)

    for id, path in pairs(paths) do
        local cleanPath = cleanupMaterialPath(path)

        tool.materialsLookup[cleanPath] = id
    end
end

function tool.getMaterials()
    local paths = brushHelper.getValidTiles(tool.layer)
    local placements = {}

    for displayName, id in pairs(tool.materialsLookup) do
        table.insert(placements, {
            name = id,
            displayName = displayName
        })
    end

    return placements
end

function tool.setMaterial(material)
    local paths = brushHelper.getValidTiles(tool.layer)

    if paths[material] then
        tool.material = material

    else
        local fromLookup = tool.materialsLookup[material]

        if fromLookup then
            tool.material = fromLookup
        end
    end
end

function tool.setLayer(layer)
    tool.layer = layer

    updateMaterialLookup()
end

function tool.mouseclicked(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton
    local cloneButton = configs.editor.objectCloneButton

    if button == actionButton then
        handleActionClick(x, y)

    elseif button == cloneButton then
        handleCloneClick(x, y)
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local actionButton = configs.editor.toolActionButton

    if love.mouse.isDown(actionButton) then
        handleActionClick(x, y)
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local hudText = string.format("Cursor: %s, %s (%s, %s)", tx + 1, ty + 1, px, py)

        love.graphics.printf(hudText, 20, 120, viewportHandler.viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)

        viewportHandler.drawRelativeTo(room.x, room.y, function()
            drawing.callKeepOriginalColor(function()
                love.graphics.setColor(colors.brushColor)
                love.graphics.rectangle("line", tx * 8, ty * 8, 8, 8)
            end)
        end)
    end
end


return tool