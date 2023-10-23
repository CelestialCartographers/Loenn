local loadedState = require("loaded_state")
local utils = require("utils")
local celesteRender = require("celeste_render")
local mapItemUtils = require("map_item_utils")

local mapImageGenerator = {}

local function getImageState(map)
    local imageState = utils.deepcopy(loadedState)

    local tlx, tly, brx, bry = mapItemUtils.getMapBounds(map)
    local width, height = brx - tlx, bry - tly

    imageState.map = map
    imageState.viewport = {
        visible = true,
        scale = 1,
        x = tlx,
        y = tly,
        width = width,
        height = height
    }
    imageState.selectedItemType = "table"
    imageState.selectedItem = {}
    imageState.showRoomBackground = false
    imageState.showRoomBorders = false

    -- TODO - Improve, this is a bit of a hack
    function imageState.getLayerVisible(layer)
        if layer == "triggers" then
            return false
        end

        return true
    end

    return imageState
end

function mapImageGenerator.getMapImage(map)
    map = map or loadedState.map

    if not map then
        return
    end

    local imageState = getImageState(map)
    local width, height = imageState.viewport.width, imageState.viewport.height
    local success, canvas = pcall(love.graphics.newCanvas, width, height)

    if success then
        -- Redraw all rooms with new state info
        for _, room in ipairs(map.rooms) do
            celesteRender.forceRedrawRoom(room, imageState, true)
        end

        canvas:renderTo(function()
            celesteRender.drawMap(imageState)
        end)

        celesteRender.invalidateRoomCache()

        return canvas
    end

    return false
end

function mapImageGenerator.saveMapImage(filename, map)
    local canvas = mapImageGenerator.getMapImage(map)

    if canvas then
        local imageData = canvas:newImageData()
        local fh = io.open(filename, "wb")

        if fh then
            local encoded = imageData:encode("png")
            local data = encoded:getString()

            fh:write(data)
            fh:close()

            -- Validate that the png is valid
            local success, loadedImage = pcall(love.graphics.newImage, filename)

            return success
        end
    end

    return false
end

return mapImageGenerator