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
        rectangles = {},
        previousX = 0,
        previousY = 0
    }

    table.insert(textureAtlas.atlases, atlas)
end

-- TODO - Check if added already?
-- TODO - Use actual algorithm
function textureAtlas.addImage(atlas, image, filename, layer)
    local width, height = image:getDimensions()

    for x = atlas.previousX, atlas.width - 1, 16 do
        for y = atlas.previousY, atlas.height - 1, 16 do
            local areaClear = true

            if x + width <= atlas.width and y + height <= atlas.height then
                for i, rectangle in ipairs(atlas.rectangles) do
                    if utils.aabbCheckInline(x, y, width, height, rectangle.x, rectangle.y, rectangle.width, rectangle.height) then
                        areaClear = false

                        break
                    end
                end

            else
                areaClear = false
            end

            if areaClear then
                table.insert(atlas.rectangles, utils.rectangle(x, y, width, height))

                atlas.previousX = x
                atlas.previousY = y

                local previousCanvas = love.graphics.getCanvas()

                love.graphics.setCanvas(textureAtlas.canvasArray, layer)
                love.graphics.draw(image, x, y)
                love.graphics.setCanvas(previousCanvas)

                return true, atlas.image, x, y
            end
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

return textureAtlas