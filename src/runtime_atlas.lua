local utils = require("utils")

local textureAtlas = {}

textureAtlas.atlases = {}
textureAtlas._MT = {}

textureAtlas.width = 4096
textureAtlas.height = 4096

textureAtlas.canvases = 16
textureAtlas.canvasArray = love.graphics.newCanvas(textureAtlas.width, textureAtlas.height, textureAtlas.canvases, {type="array"})

function textureAtlas.clear()
    for i, atlas in ipairs(textureAtlas.atlases) do
        if atlas.image then
            atlas.image:release()
        end

        textureAtlas.atlases[i] = nil
    end
end

-- TODO - Handle growing the canvas array
-- This just makes new images use themselves instead of adding to atlas
function textureAtlas.addAtlas()
    local atlasNumber = #textureAtlas.atlases + 1
    local atlasName = string.format("Runtime Atlas #%s", atlasNumber)
    local canvas = textureAtlas.canvasArray

    if atlasNumber > textureAtlas.canvases then
        return
    end

    local atlas = {
        image = canvas,
        width = textureAtlas.width,
        height = textureAtlas.height,
        filename = atlasName,
        dataName = atlasName,
        rectangles = {utils.rectangle(0, 0, textureAtlas.width, textureAtlas.height)}
    }

    table.insert(textureAtlas.atlases, atlas)
end

-- TODO - Check if added already?
function textureAtlas.addImage(atlas, image, filename, layer)
    local width, height = image:getDimensions()

    for i = 1, #atlas.rectangles do
        local rectangle = atlas.rectangles[i]

        -- Find free space
        if width <= rectangle.width and height <= rectangle.height then
            local x, y = rectangle.x, rectangle.y

            -- Find remaining free space after inserting the new image
            local remainingSpace = utils.subtractRectangle(rectangle, utils.rectangle(x, y, width, height))

            table.remove(atlas.rectangles, i)

            for _, remaining in ipairs(remainingSpace) do
                table.insert(atlas.rectangles, remaining)
            end

            -- TODO merge adjacent rectangles
            -- TODO overlap rectangles

            table.sort(atlas.rectangles, function(r1, r2)
                return r1.width == r2.width and r1.height < r2.height or r1.width < r2.width
            end)

            -- Add the image on the canvas

            local previousCanvas = love.graphics.getCanvas()

            love.graphics.setCanvas(textureAtlas.canvasArray, layer)
            love.graphics.draw(image, x, y)
            love.graphics.setCanvas(previousCanvas)

            return true, atlas.image, x, y
        end
    end

    return false, nil, 0, 0
end

function textureAtlas.addImageFirstAtlas(image, filename, createIfNeeded, onlyCheck)
    for i, atlas in ipairs(textureAtlas.atlases) do
        if not onlyCheck or onlyCheck and onlyCheck == i then
            local fit, atlasImage, x, y = textureAtlas.addImage(atlas, image, filename, i)
            if fit then
                return atlasImage, x, y, i
            end
        end
    end

    if createIfNeeded ~= false then
        textureAtlas.addAtlas()

        return textureAtlas.addImageFirstAtlas(image, filename, false, #textureAtlas.atlases)
    end

    return image, 0, 0
end

function textureAtlas.dumpCanvasImages()
    for i = 1, #textureAtlas.atlases do
        local data = textureAtlas.canvasArray:newImageData(i)

        data:encode("png", "canvas_dump_" .. tostring(i) .. ".png")
        data:release()
    end
end

return textureAtlas