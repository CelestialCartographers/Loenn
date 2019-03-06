local utils = require("utils")
local binfile = require("binfile")

local function loadDataImage(fn)
    local fh = utils.getFileHandle(fn, "rb")

    local width = binfile.readLong(fh)
    local height = binfile.readLong(fh)
    local hasAlpha = binfile.readBool(fh)

    local image = love.image.newImageData(width, height)

    local repeatsLeft = 0
    local pixel

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if repeatsLeft == 0 then
                local rep = binfile.readByte(fh)
                repeatsLeft = rep - 1

                if hasAlpha then
                    local alpha = binfile.readByte(fh)

                    if alpha > 0 then
                        local b, g, r = binfile.readByte(fh) / 255, binfile.readByte(fh) / 255, binfile.readByte(fh) / 255
                        pixel = {r, g, b, alpha / 255}

                    else
                        pixel = {0, 0, 0, 0}
                    end

                else
                    local b, g, r = binfile.readByte(fh) / 255, binfile.readByte(fh) / 255, binfile.readByte(fh) / 255
                    pixel = {r, g, b, alpha / 255}
                end

                image:setPixel(x, y, unpack(pixel))

            else
                image:setPixel(x, y, unpack(pixel))
                repeatsLeft -= 1
            end
        end
    end

    return love.graphics.newImage(image)
end

local function loadSpriteAtlas(metaFn, atlasDir)
    local fh = utils.getFileHandle(metaFn, "rb")

    -- Get rid of headers
    binfile.readSignedLong(fh)
    binfile.readString(fh)
    binfile.readSignedLong(fh)

    local count = binfile.readShort(fh)

    local res = {
        _imageMeta = $(),
        _count = count
    }

    for i = 1, count do
        local dataFile = binfile.readString(fh)
        local sprites = binfile.readSignedShort(fh)

        local dataFilePath = atlasDir .. dataFile .. ".data"

        local spritesImage = loadDataImage(dataFilePath)
        local spritesWidth, spritesHeight = spritesImage:getDimensions

        res._imageMeta += {
            image = spritesImage,
            width = spritesWidth,
            height = spritesHeight,
            path = dataFilePath
        }

        for j = 1, sprites do
            local pathRaw = binfile.readString(fh)
            local path = pathRaw:gsub("\\", "/")

            local sprite = {
                x = binfile.readSignedShort(fh),
                y = binfile.readSignedShort(fh),
                
                width = binfile.readSignedShort(fh),
                height = binfile.readSignedShort(fh),
                
                offsetX = binfile.readSignedShort(fh),
                offsetY = binfile.readSignedShort(fh),
                realWidth = binfile.readSignedShort(fh),
                realHeight = binfile.readSignedShort(fh),

                image = spritesImage,
                filename = spritesFn
            }

            sprite.quad = love.graphics.newQuad(sprite.x, sprite.y, sprite.width, sprite.height, spritesWidth, spritesHeight)
            res[path] = sprite
        end
    end

    fh:close()

    return res
end

return {
    loadSpriteAtlas = loadSpriteAtlas,
    loadDataImage = loadDataImage
}