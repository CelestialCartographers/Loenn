local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local fonts = require("fonts")

local tool = {}

tool._type = "tool"

tool.name = "Brush"
tool.image = nil

-- Test tile placement
function tool.mousepressed(x, y, button, istouch, pressed)
    local room = state.selectedRoom

    if room then
        local matrix = room.tilesFg.matrix
        local tx, ty = viewportHandler.pixelToTileCoordinates(viewportHandler.getRoomCoordindates(state.selectedRoom, x, y))

        matrix:set0(tx, ty, "5")
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local room = state.selectedRoom

    if room then
        local px, py = viewportHandler.getRoomCoordindates(state.selectedRoom, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        hudText = string.format("Cursor: %s, %s (%s, %s)", tx + 1, ty + 1, px, py)

    else
        hudText = ""
    end
end

function tool.draw()
    local room = state.selectedRoom

    if room then
        local px, py = viewportHandler.getRoomCoordindates(state.selectedRoom)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local hudText = string.format("Cursor: %s, %s (%s, %s)", tx + 1, ty + 1, px, py)

        love.graphics.printf(hudText, 20, 120, viewportHandler.viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)
    end
end


return tool