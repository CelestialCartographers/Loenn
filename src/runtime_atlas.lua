local utils = require("utils")

local textureAtlas = {}

textureAtlas.atlases = {}
textureAtlas._MT = {}

function textureAtlas.clear()
    for i, atlas in ipairs(textureAtlas.atlases) do
        if atlas.image then
            atlas.image:release()
        end

        textureAtlas.atlases[i] = nil
    end
end

function textureAtlas.addAtlas(width, height)
    width, height = width or 4096, height or 4096

    local atlasNumber = #textureAtlas.atlases + 1
    local atlasName = string.format("Runtime Atlas #%s", atlasNumber)
    local texture = love.image.newImageData(width, height)
    local atlas = {
        image = atlasName,
        imageData = texture,
        width = width,
        height = height,
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
function textureAtlas.addImage(atlas, imageData, filename)
    local width, height = imageData:getDimensions()

    for x = atlas.previousX, atlas.width - 1, 16 do
        for y = atlas.previousY, atlas.height - 1, 16 do
            local areaClear = true

            if x + width < atlas.width and y + height < atlas.height then
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
                atlas.imageData:paste(imageData, x, y, 0, 0, width, height)
                table.insert(atlas.rectangles, utils.rectangle(x, y, width, height))

                atlas.previousX = x
                atlas.previousY = y

                return true, atlas.imageData, x, y
            end
        end
    end

    return false, nil, 0, 0
end

function textureAtlas.addImageFirstAtlas(imageData, filename, createIfNeeded, onlyCheck)
    for i, atlas in ipairs(textureAtlas.atlases) do
        if not onlyCheck or onlyCheck and onlyCheck == i then
            local fit, atlasImageData, x, y = textureAtlas.addImage(atlas, imageData, filename)

            if fit then
                return atlasImageData, x, y
            end
        end
    end

    if createIfNeeded ~= false then
        textureAtlas.addAtlas()

        return textureAtlas.addImageFirstAtlas(imageData, filename, false, #textureAtlas.atlases)
    end

    return imageData, 0, 0
end

return textureAtlas