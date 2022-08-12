local themes = require("ui.themes")
local utils = require("utils")

local iconUtils = {}

local iconSizes = {64, 32, 24, 16}
local iconCache = {}

local previousThemeName = themes.defaultThemeName

function iconUtils.clearCache(name)
    if name then
        for _, size in ipairs(iconSizes) do
            local cacheKey = string.format("%s-%s", name, size)

            iconCache[cacheKey] = nil
        end

    else
        iconCache = {}
    end
end

function iconUtils.getBestSize(maxSize)
    for _, size in ipairs(iconSizes) do
        if size <= maxSize then
            return size
        end
    end
end

function iconUtils.getIcon(name, maxSize, allowCustom)
    local currentTheme = themes.currentTheme

    -- Invalidate all icons if theme has changed
    if currentTheme.name ~= previousThemeName then
        iconUtils.clearCache()

        previousThemeName = currentTheme.name
    end

    local targetSize = iconUtils.getBestSize(maxSize)
    local cacheKey = string.format("%s-%s", name, targetSize)

    if iconCache[cacheKey] then
        return unpack(iconCache[cacheKey])
    end

    local iconsPath = "ui/assets/icons/"

    if currentTheme and currentTheme.iconsPath then
        if allowCustom ~= false then
            iconsPath = currentTheme.iconsPath
        end
    end

    -- Add image to cache for all sizes that fit
    local image
    local actualSize
    local relevantSizes = {}

    for _, size in ipairs(iconSizes) do
        if size <= maxSize then
            table.insert(relevantSizes, size)

            local path = utils.joinpath(iconsPath, string.format("%s-%s.png", name, size))
            local fileInfo = love.filesystem.getInfo(path) or utils.pathAttributes(path)

            if fileInfo then
                image = love.graphics.newImage(path)
                actualSize = size

                break
            end
        end
    end

    if image then
        for _, size in ipairs(relevantSizes) do
            cacheKey = string.format("%s-%s", name, size)
            iconCache[cacheKey] = {image, actualSize}
        end

        return image, actualSize
    end

    -- Fallback to default theme
    if allowCustom ~= false then
        return iconUtils.getIcon(name, maxSize, false)
    end
end

return iconUtils