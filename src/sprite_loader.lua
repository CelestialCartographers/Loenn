local utils = require("utils")
local binfile = require("binfile")
local fileLocations = require("file_locations")
local tasks = require("task")
local filesystem = require("filesystem")
local config = require("config")
local threadHandler = require("thread_handler")

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

        tasks.yield()
    end

    local res = love.graphics.newImage(image)

    tasks.update(res, image)

    return res, image
end

function spriteLoader.getCachedDataImage(dataFile)
    local storageDir = fileLocations.getStorageDir()
    local path = utils.joinpath(storageDir, "Cache", dataFile .. ".png")

    if filesystem.isFile(path) then
        return utils.newImage(path, false)
    end
end

function spriteLoader.loadSpriteAtlas(metaFn, atlasDir, useCache)
    local fh = utils.getFileHandle(utils.joinpath(atlasDir, metaFn), "rb")

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
        local spritesImage, spritesImageData

        if useCache then
            spritesImage, spritesImageData = spriteLoader.getCachedDataImage(dataFile), false
        end

        if not spritesImage then
            spritesImage, spritesImageData = spriteLoader.loadDataImage(dataFilePath)
        end

        local spritesWidth, spritesHeight = spritesImage:getDimensions

        table.insert(res._imageMeta, {
            image = spritesImage,
            imageData = spritesImageData,
            width = spritesWidth,
            height = spritesHeight,
            filename = dataFilePath,
            dataName = dataFile
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

                loadedAt = os.time()
            }

            sprite.quad = love.graphics.newQuad(sprite.x, sprite.y, sprite.width, sprite.height, spritesWidth, spritesHeight)
            res[path] = sprite
        end

        if i ~= count then
            tasks.yield()
        end
    end

    fh:close()

    tasks.update(res)

    return res
end

local imageCachingCode = [[
require("love.image")

local args = {...}
local channelName, filename, imageData = unpack(args)

local fh = io.open(filename, "wb")

if fh then
    fh:write(imageData:encode("png"):getString())
    fh:close()
end
]]

-- TODO - Check if all .pngs are there?
function spriteLoader.getCacheOrLoadSpriteAtlas(metaFn, atlasDir)
    local storageDir = fileLocations.getStorageDir()
    local storageCacheDir = utils.joinpath(storageDir, "Cache")
    local configPath = utils.joinpath(storageDir, "cache.conf")
    local metaPath = utils.joinpath(atlasDir, metaFn)

    local cacheConfig = config.readConfig(configPath)
    local metaData = cacheConfig[metaFn]

    if not metaData or filesystem.mtime(metaPath) > metaData.mtime then
        if not filesystem.isDirectory(storageCacheDir) then
            filesystem.mkdir(storageCacheDir)
        end

        if metaData then
            for _, dataName in ipairs(metaData.filenames) do
                local filename = utils.joinpath(storageCacheDir, dataName .. ".png")

                os.remove(filename)
            end
        end

        local atlas = spriteLoader.loadSpriteAtlas(metaFn, atlasDir, false)

        metaData = {
            mtime = os.time(),
            filenames = {}
        }

        for _, imageMeta in ipairs(atlas._imageMeta) do
            local filename = utils.joinpath(storageCacheDir, imageMeta.dataName) .. ".png"

            threadHandler.createStartWithCallback(imageCachingCode, function() end, filename, imageMeta.imageData)
            table.insert(metaData.filenames, imageMeta.dataName)

            tasks.yield()
        end

        cacheConfig[metaFn] = metaData

        return atlas

    else
        return spriteLoader.loadSpriteAtlas(metaFn, atlasDir, true)
    end
end

return spriteLoader