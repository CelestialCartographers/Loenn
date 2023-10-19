local atlases = require("atlases")
local languageRegistry = require("language_registry")

local scenery = {}

scenery.usedTilesCache = nil

local sceneryPath = "tilesets/scenery"

-- Figure out which tiles are used and cache it
function scenery.getSceneryTiles(force)
    if scenery.usedTilesCache and not force then
        return scenery.usedTilesCache
    end

    local spriteMeta = atlases.getResource(sceneryPath, "Gameplay")

    if spriteMeta then
        local image = spriteMeta.image
        local startX = spriteMeta.x
        local startY = spriteMeta.y
        local realWidth = spriteMeta.realWidth
        local realHeight = spriteMeta.realHeight
        local sceneryWidth, sceneryHeight = math.ceil(realWidth / 8), math.ceil(realHeight / 8)
        local canvas = love.graphics.newCanvas(spriteMeta.width, spriteMeta.height)
        local usedSceneryTiles = {}

        canvas:renderTo(function()
            love.graphics.draw(image, -startX, -startY)
        end)

        local imageData = canvas:newImageData()

        for y = 0, spriteMeta.height - 1 do
            for x = 0, spriteMeta.width - 1 do
                local quadX = math.floor(x / 8)
                local quadY = math.floor(y / 8)
                local sceneryTile = quadX + quadY * sceneryWidth

                if not usedSceneryTiles[sceneryTile] then
                    local r, g, b, a = imageData:getPixel(x, y)

                    if r > 0 and g > 0 and b > 0 and a > 0 then
                        usedSceneryTiles[sceneryTile] = true
                    end
                end
            end
        end

        scenery.usedTilesCache = {}

        for id, value in pairs(usedSceneryTiles) do
            table.insert(scenery.usedTilesCache, id)
        end

        table.sort(scenery.usedTilesCache)

        return scenery.usedTilesCache
    end
end

function scenery.getMaterialLookup(addBlank)
    local sceneryTiles = scenery.getSceneryTiles()
    local lookup = {}
    local language = languageRegistry.getLanguage()
    local displayFormat = "%s (%s)"

    for i, id in ipairs(sceneryTiles) do
        local displayName = language.sceneryTiles.names[tostring(id)]

        if displayName._exists then
            lookup[string.format(displayFormat, displayName, id)] = id

        else
            local unknownName = language.sceneryTiles.names.unknown

            lookup[string.format(displayFormat, unknownName, id)] = id
        end
    end

    if addBlank ~= false then
        local displayName = tostring(language.sceneryTiles.names["-1"])

        lookup[string.format(displayFormat, displayName, id)] = -1
    end

    return lookup
end

return scenery