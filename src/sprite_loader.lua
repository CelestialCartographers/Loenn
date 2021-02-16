local utils = require("utils")
local fileLocations = require("file_locations")
local tasks = require("task")
local filesystem = require("filesystem")
local config = require("config")
local threadHandler = require("thread_handler")
local binaryReader = require("binary_reader")
local runtimeAtlas = require("runtime_atlas")

local spriteLoader = {}

-- TODO - See if this can be optimized
function spriteLoader.loadDataImage(fn)
    local fh = utils.getFileHandle(fn, "rb")
    local reader = binaryReader(fh)

    local width = reader:readLong()
    local height = reader:readLong()
    local hasAlpha = reader:readBool()

    local image = love.image.newImageData(width, height)

    local repeatsLeft = 0
    local r, g, b, a

    for y = 0, height - 1 do
        for x = 0, width - 1 do
            if repeatsLeft == 0 then
                local rep = reader:readByte()
                repeatsLeft = rep - 1

                if hasAlpha then
                    local alpha = reader:readByte()

                    if alpha > 0 then
                        b, g, r = reader:readByte() / 255, reader:readByte() / 255, reader:readByte() / 255
                        a = alpha / 255

                    else
                        r, g, b, a = 0, 0, 0, 0
                    end

                else
                    b, g, r = reader:readByte() / 255, reader:readByte() / 255, reader:readByte() / 255
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
    local path = utils.joinpath(storageDir, "Cache", "Data", dataFile .. ".png")

    if filesystem.isFile(path) then
        return utils.newImage(path, false)
    end
end

local filenameCheckTimesCache = {}
local filenameImageDataCache = {}

local function getExternalImageData(filename, cacheDuration)
    cacheDuration = cacheDuration or 10

    local now = os.time()
    local lastCheck = filenameCheckTimesCache[filename]

    if not lastCheck or now > lastCheck + cacheDuration then
        local success, image = pcall(love.image.newImageData, filename)

        filenameCheckTimesCache[filename] = os.time()
        filenameImageDataCache[filename] = success and image
    end

    return filenameImageDataCache[filename]
end

function spriteLoader.loadExternalSprite(filename)
    local loadedImageData = getExternalImageData(filename)

    if not loadedImageData then
        return
    end

    local image = love.graphics.newImage(loadedImageData)
    -- TODO - Consider using the runtime atlases later when this is more complete
    --local imageData, x, y = runtimeAtlas.addImageFirstAtlas(loadedImageData, filename)
    local imageData, x, y = loadedImageData, 0, 0

    local imageWidth, imageHeight = image:getDimensions()
    local atlasWidth, atlasHeight = imageData:getDimensions()
    local meta = {
        image = image,
        imageData = imageData,
        width = imageWidth,
        height = imageHeight,
        filename = "filename"
    }

    local sprite = {
        x = x,
        y = y,

        width = imageWidth,
        height = imageHeight,

        offsetX = 0,
        offsetY = 0,
        realWidth = imageWidth,
        realHeight = imageHeight,

        image = image,
        imageData = imageData,
        meta = meta,
        filename = filename,

        loadedAt = os.time()
    }

    sprite.quad = love.graphics.newQuad(x, y, imageWidth, imageHeight, atlasWidth, atlasHeight)

    return sprite
end

function spriteLoader.loadSpriteAtlas(metaFn, atlasDir, useCache)
    local fh = utils.getFileHandle(utils.joinpath(atlasDir, metaFn), "rb")
    local reader = binaryReader(fh)

    -- Get rid of headers
    reader:readSignedLong()
    reader:readString()
    reader:readSignedLong()

    local count = reader:readShort()

    local res = {
        _imageMeta = {},
        _count = count
    }

    for i = 1, count do
        local dataFile = reader:readString()
        local sprites = reader:readSignedShort()

        local dataFilePath = utils.joinpath(atlasDir, dataFile .. ".data")
        local spritesImage, spritesImageData

        if useCache then
            spritesImage, spritesImageData = spriteLoader.getCachedDataImage(dataFile)
        end

        if not spritesImage then
            spritesImage, spritesImageData = spriteLoader.loadDataImage(dataFilePath)
        end

        local spritesWidth, spritesHeight = spritesImage:getDimensions()

        table.insert(res._imageMeta, {
            image = spritesImage,
            imageData = spritesImageData,
            width = spritesWidth,
            height = spritesHeight,
            filename = dataFilePath,
            dataName = dataFile
        })

        for j = 1, sprites do
            local pathRaw = reader:readString()
            local path = pathRaw:gsub("\\", "/")

            local sprite = {
                x = reader:readSignedShort(),
                y = reader:readSignedShort(),

                width = reader:readSignedShort(),
                height = reader:readSignedShort(),

                offsetX = reader:readSignedShort(),
                offsetY = reader:readSignedShort(),
                realWidth = reader:readSignedShort(),
                realHeight = reader:readSignedShort(),

                image = spritesImage,
                imageData = spritesImageData,
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
    local storageCacheDataDir = utils.joinpath(storageCacheDir, "Data")
    local configPath = utils.joinpath(storageDir, "Cache", "cache.conf")
    local metaPath = utils.joinpath(atlasDir, metaFn)

    local cacheConfig = config.readConfig(configPath)
    local metaData = cacheConfig[metaFn]

    if not metaData or filesystem.mtime(metaPath) ~= metaData.mtime then
        if not filesystem.isDirectory(storageCacheDir) then
            filesystem.mkdir(storageCacheDir)
        end

        if not filesystem.isDirectory(storageCacheDataDir) then
            filesystem.mkdir(storageCacheDataDir)
        end

        if metaData then
            for _, dataName in ipairs(metaData.filenames) do
                local filename = utils.joinpath(storageCacheDataDir, dataName .. ".png")

                os.remove(filename)
            end
        end

        local atlas = spriteLoader.loadSpriteAtlas(metaFn, atlasDir, false)

        metaData = {
            mtime = os.time(),
            filenames = {}
        }

        for _, imageMeta in ipairs(atlas._imageMeta) do
            local filename = utils.joinpath(storageCacheDataDir, imageMeta.dataName .. ".png")

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