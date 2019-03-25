local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local fonts = require("fonts")
local matrix = require("matrix")
local celesteRender = require("celeste_render")

local tool = {}

tool._type = "tool"

tool.name = "Brush"
tool.image = nil
tool.layer = "tilesFg"
tool.material = "a"

local lastX, lastY = -1, -1

local previewMatrix = matrix.filled("0", 5, 5)
local previewBatch = nil

-- Test tile placement
function tool.mousepressed(x, y, button, istouch, pressed)
    local room = state.selectedRoom

    if room then
        local tiles = room[tool.layer]
        local matrix = tiles.matrix 

        local tx, ty = viewportHandler.pixelToTileCoordinates(viewportHandler.getRoomCoordindates(state.selectedRoom, x, y))

        -- TODO - Update the room batch and redraw
        matrix:set(tx + 1, ty + 1, tool.material)
        celesteRender.invalidateRoomCache(room.name)
    end
end

function tool.mousemoved(x, y, dx, dy, istouch)
    local room = state.selectedRoom

    if room then
        local tiles = room[tool.layer]
        local matrix = tiles.matrix 

        local px, py = viewportHandler.getRoomCoordindates(state.selectedRoom, x, y)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        if tx ~= lastX or ty ~= lastY then
            for i = -2, 2 do
                for j = -2, 2 do
                    previewMatrix:set(i + 3, j + 3, matrix:get0(tx + i, ty + j, "0"))
                end
            end

            previewMatrix:set(3, 3, tool.material)

            lastX = tx
            lastY = ty
            previewBatch = nil
        end
    end
end

function tool.draw()
    local room = state.selectedRoom

    if room then
        local px, py = viewportHandler.getRoomCoordindates(room)
        local tx, ty = viewportHandler.pixelToTileCoordinates(px, py)

        local hudText = string.format("Cursor: %s, %s (%s, %s)", tx + 1, ty + 1, px, py)

        love.graphics.printf(hudText, 20, 120, viewportHandler.viewport.width, "left", 0, fonts.fontScale, fonts.fontScale)

        viewportHandler.drawRelativeTo(room.x, room.y, (->
            if not previewBatch then
                local tiles = {matrix = previewMatrix}
                local fg = tool.layer == "tilesFg"
                local meta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg

                previewBatch = celesteRender.getTilesBatch(tiles, meta, fg)
            end

            love.graphics.push()
            love.graphics.translate(tx * 8 - 16, ty * 8 - 16)

            previewBatch:draw()
            love.graphics.setColor(0.3, 0.3, 0.3, 0.3)
            love.graphics.rectangle("line", 16, 16, 8, 8)

            love.graphics.pop()

            return -- TODO - Vex please fix
        ))
    end
end


return tool