local utils = require("utils")
local binfile = require("binfile")

local spriteLoader = {}

-- TODO - See if this can be optimized
function spriteLoader.loadDataImage(fn)
    local fh = utils.getFileHandle(fn, "rb")

    local width = binfile.readLong(fh)
    local height = binfile.readLong(fh)
    local hasAlpha = binfile.readBool(fh)

    local image = love.image.newImageData(width, height)

    local repeatsLeft = 0
    local r, g, b, a

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if repeatsLeft == 0 then
                local rep = binfile.readByte(fh)
                repeatsLeft = rep - 1

                if hasAlpha then
                    local alpha = binfile.readByte(fh)

                    if alpha > 0 then
                        b, g, r = binfile.readByte(fh) / 255, binfile.readByte(fh) / 255, binfile.readByte(fh) / 255
                        a = alpha / 255

                    else
                        r, g, b, a = 0, 0, 0, 0
                    end

                else
                    b, g, r = binfile.readByte(fh) / 255, binfile.readByte(fh) / 255, binfile.readByte(fh) / 255
                    a = 1
                end

                image:setPixel(x, y, r, g, b, a)

            else
                image:setPixel(x, y, r, g, b, a)
                repeatsLeft -= 1
            end
        end

        coroutine.yield()
    end

    local res = love.graphics.newImage(image)

    coroutine.yield(res)

    return res
end

function spriteLoader.loadSpriteAtlas(metaFn, atlasDir)
    local fh = utils.getFileHandle(metaFn, "rb")

    -- Get rid of headers
    binfile.readSignedLong(fh)
    binfile.readString(fh)
    binfile.readSignedLong(fh)

    local count = binfile.readShort(fh)

    local res = {
        _imageMeta = {},
        _count = count
    }

    for i = 1, count do
        local dataFile = binfile.readString(fh)
        local sprites = binfile.readSignedShort(fh)

        local dataFilePath = utils.joinpath(atlasDir, dataFile .. ".data")

        local spritesImage = spriteLoader.loadDataImage(dataFilePath)
        local spritesWidth, spritesHeight = spritesImage:getDimensions

        table.insert(res._imageMeta, {
            image = spritesImage,
            width = spritesWidth,
            height = spritesHeight,
            path = dataFilePath
        })

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
                filename = dataFilePath,

                loadedAt = love.timer.getTime()
            }

            sprite.quad = love.graphics.newQuad(sprite.x, sprite.y, sprite.width, sprite.height, spritesWidth, spritesHeight)
            res[path] = sprite
        end

        if i ~= count then
            coroutine.yield()
        end
    end

    fh:close()

    coroutine.yield(res)

    return res
end

return spriteLoader