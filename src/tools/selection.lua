local state = require("loaded_state")
local utils = require("utils")
local configs = require("configs")
local celesteRender = require("celeste_render")
local viewportHandler = require("viewport_handler")
local drawing = require("drawing")
local colors = require("colors")

local tool = {}

tool._type = "tool"
tool.name = "Selection"
tool.image = nil

tool.layer = "entities"

local selection = nil

local function redrawTargetLayer(room)
    -- TODO - Redraw more efficiently
    celesteRender.invalidateRoomCache(room, tool.layer)
    celesteRender.invalidateRoomCache(room, "complete")
    celesteRender.forceRoomBatchRender(room, state.viewport)
end

local function getCursorPositionInRoom(x, y)
    local room = state.getSelectedRoom()
    local px, py = viewportHandler.getRoomCoordindates(room, x, y)

    return px, py
end

function tool.mousepressed(x, y, button, istouch, presses)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local px, py = getCursorPositionInRoom(x, y)

        selection = utils.rectangle(px, py, 0, 0)
    end
end

function tool.mousedragmoved(dx, dy, button, istouch)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local viewport = viewportHandler.viewport

        if selection then
            selection.width += dx / viewport.scale
            selection.height += dy / viewport.scale
        end
    end
end

function tool.mousedragged(startX, startY, button, dx, dy)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local px, py = getCursorPositionInRoom(startX, startY)
        local viewport = viewportHandler.viewport

        selection = utils.rectangle(px, py, dx / viewport.scale, dy / viewport.scale)
    end
end

-- TODO - Implement, this is test code
function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()

    local ox = key == "a" and -8 or key == "d" and 8 or 0
    local oy = key == "w" and -8 or key == "s" and 8 or 0

    if room and ox ~= 0 or oy ~= 0 then
        for _, entity in ipairs(room.entities) do
            entity.x += ox
            entity.y += oy
        end

        redrawTargetLayer(room)
    end
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room and selection then
        -- Don't render if selection rectangle is too small, weird visuals
        if math.abs(selection.width) > 1 and math.abs(selection.height) > 1 then
            viewportHandler.drawRelativeTo(room.x, room.y, function()
                drawing.callKeepOriginalColor(function()
                    local x, y = selection.x, selection.y
                    local width, height = selection.width, selection.height

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

return tool