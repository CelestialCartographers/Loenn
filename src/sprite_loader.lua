local utils = require("utils")
local fileLocations = require("file_locations")
local tasks = require("utils.tasks")
local filesystem = require("utils.filesystem")
local config = require("utils.config")
local threadHandler = require("utils.threads")
local binaryReader = require("utils.binary_reader")
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
                        a = alpha / 255
                        b, g, r = reader:readByte() / 255 / a, reader:readByte() / 255 / a, reader:readByte() / 255 / a

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

function spriteLoader.saveCachedDataImage(dataFile, image, imageData)
    local storageDir = fileLocations.getStorageDir()
    local path = utils.joinpath(storageDir, "Cache", "Data", dataFile .. ".png")

    local fh = io.open(path, "wb")

    if fh then
        fh:write(imageData:encode("png"):getString())
        fh:close()
    end
end

local filenameCheckTimesCache = {}
local filenameImageDataCache = {}

local function getExternalImage(filename, cacheDuration)
    cacheDuration = cacheDuration or 10

    local now = os.time()
    local lastCheck = filenameCheckTimesCache[filename]

    if not lastCheck or now > lastCheck + cacheDuration then
        local success, image = pcall(love.graphics.newImage, filename)

        filenameCheckTimesCache[filename] = os.time()
        filenameImageDataCache[filename] = success and image
    end

    return filenameImageDataCache[filename]
end

-- We can keep quads since atlas sizes matches
function spriteLoader.addAtlasToRuntimeAtlas(atlas, filename)
    local metaLookup = {}

    for i, imageMeta in pairs(atlas._imageMeta) do
        local atlasImage, x, y, layer = runtimeAtlas.addImageFirstAtlas(imageMeta.image, filename)

        metaLookup[imageMeta.image] = {
            image = atlasImage,
            layer = layer
        }
    end

    for path, sprite in pairs(atlas) do
        if type(sprite) == "table" and sprite.loadedAt then
            local newImage = metaLookup[sprite.image].image
            local layer = metaLookup[sprite.image].layer

            sprite.image = newImage
            sprite.layer = layer
        end
    end
end

function spriteLoader.loadExternalSprite(filename)
    local image = getExternalImage(filename)

    if not image then
        return
    end

    local atlasImage, x, y, layer = runtimeAtlas.addImageFirstAtlas(image, filename)

    local imageWidth, imageHeight = image:getDimensions()
    local atlasWidth, atlasHeight = atlasImage:getDimensions()

    local meta = {
        image = atlasImage,
        layer = layer,
        width = imageWidth,
        height = imageHeight,
        filename = filename
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

        image = atlasImage,
        layer = layer,
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

            if useCache then
                spriteLoader.saveCachedDataImage(dataFile, spritesImage, spritesImageData)
            end
        end

        local spritesWidth, spritesHeight = spritesImage:getDimensions()
        local meta = {
            image = spritesImage,
            imageData = spritesImageData,
            width = spritesWidth,
            height = spritesHeight,
            filename = dataFilePath,
            dataName = dataFile
        }

        table.insert(res._imageMeta, meta)

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
                meta = meta,
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
            mtime = filesystem.mtime(metaPath),
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