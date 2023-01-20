local celesteRender = require("celeste_render")
local utils = require("utils")
local matrix = require("utils.matrix")
local drawableSprite = require("structs.drawable_sprite")
local drawableRectangle = require("structs.drawable_rectangle")
local colors = require("consts.colors")
local brushes = require("brushes")
local utf8 = require("utf8")

local fakeTilesHelper = {}

function fakeTilesHelper.generateFakeTilesMatrix(room, x, y, material, layer, blendIn)
    local materialType = utils.typeof(material)

    local tilesMatrix = nil
    local width, height = 5, 5

    local roomTiles = room[layer].matrix

    if materialType == "matrix" then
        local matrixWidth, matrixHeight = material:size()

        width = matrixWidth + 4
        height = matrixHeight + 4

        tilesMatrix = matrix.filled("0", width, height)

        for tx = 1, matrixWidth do
            for ty = 1, matrixHeight do
                tilesMatrix:setInbounds(tx + 2, ty + 2, material:getInbounds(tx, ty))
            end
        end

    else
        tilesMatrix = matrix.filled(material, width, height)
    end

    if blendIn ~= false then
        for ox = 1, width do
            tilesMatrix:setInbounds(ox, 1, roomTiles:get(x + ox - 3, y - 2, "0"))
            tilesMatrix:setInbounds(ox, 2, roomTiles:get(x + ox - 3, y - 1, "0"))

            tilesMatrix:setInbounds(ox, height, roomTiles:get(x + ox - 3, y + height - 3, "0"))
            tilesMatrix:setInbounds(ox, height - 1, roomTiles:get(x + ox - 3, y + height - 4, "0"))
        end

        for oy = 3, height - 2 do
            tilesMatrix:setInbounds(1, oy, roomTiles:get(x - 2, y + oy - 3, "0"))
            tilesMatrix:setInbounds(2, oy, roomTiles:get(x - 1, y + oy - 3, "0"))

            tilesMatrix:setInbounds(width, oy, roomTiles:get(x + width - 3, y + oy - 3, "0"))
            tilesMatrix:setInbounds(width - 1, oy, roomTiles:get(x + width - 4, y + oy - 3, "0"))
        end
    end

    return tilesMatrix
end

function fakeTilesHelper.generateFakeTiles(room, x, y, material, layer, blendIn)
    local fakeTilesMatrix = fakeTilesHelper.generateFakeTilesMatrix(room, x, y, material, layer, blendIn)
    local fakeTiles = {
        _type = "tiles",
        matrix = fakeTilesMatrix
    }

    return fakeTiles
end

function fakeTilesHelper.getMaterialMatrix(entity, material)
    local materialType = utils.typeof(material)

    if materialType == "string" then
        local width, height = math.ceil(entity.width / 8), math.ceil(entity.height / 8)

        return matrix.filled(material, width, height)

    elseif materialType == "matrix" then
        return material
    end
end

-- TODO - Object scenery
function fakeTilesHelper.generateFakeTilesBatch(room, x, y, fakeTiles, layer)
    local fg = layer == "tilesFg"
    local tilerMeta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local width, height = fakeTiles.matrix:size()
    local random = celesteRender.getRoomRandomMatrix(room, layer)
    local randomSlice = random:getSlice(x - 2, y - 2, x + width - 3, y + height - 3, 0)

    return celesteRender.getTilesBatch(room, fakeTiles, tilerMeta, nil, fg, randomSlice, "canvasGrid", false)
end

-- TODO - Object scenery
function fakeTilesHelper.generateFakeTilesSprites(room, x, y, fakeTiles, layer, offsetX, offsetY, color)
    offsetX = offsetX or 0
    offsetY = offsetY or 0

    local fg = layer == "tilesFg"
    local tilerMeta = fg and celesteRender.tilesMetaFg or celesteRender.tilesMetaBg
    local tileWidth, tileHeight = fakeTiles.matrix:size()
    local width, height = tileWidth * 8, tileHeight * 8
    local random = celesteRender.getRoomRandomMatrix(room, layer)
    local randomSlice = random:getSlice(x - 2, y - 2, x + tileWidth - 3, y + tileHeight - 3, 0)
    local tiles, missingTiles = celesteRender.getTilesBatch(room, fakeTiles, tilerMeta, nil, fg, randomSlice, "table", false)
    local missingColor = fg and colors.tileFGMissingColor or colors.tileBGMissingColor

    local sprites = {}

    for _, tile in ipairs(tiles) do
        local meta, quad, tileX, tileY = tile[1], tile[2], tile[3], tile[4]

        -- Filter out padding pieces for blending
        if tileX > 8 and tileX < width - 16 and tileY > 8 and tileY < height - 16 then
            local sprite = drawableSprite.fromMeta(meta, {
                justificationX = 0.0,
                justificationY = 0.0,
                x = tileX + offsetX - 16,
                y = tileY + offsetY - 16,
                quad = quad,
                color = color
            })

            table.insert(sprites, sprite)
        end
    end

    for _, missing in ipairs(missingTiles) do
        local tileX, tileY = missing[1], missing[2]

        -- Filter out padding pieces for blending
        if tileX > 1 and tileX < tileWidth - 2 and tileY > 1 and tileX < tileHeight - 2 then
            local drawX, drawY = tileX * 8 + offsetX - 16, tileY * 8 + offsetY - 16
            local sprite = drawableRectangle.fromRectangle("fill", drawX, drawY, 8, 8, missingColor)

            table.insert(sprites, sprite)
        end
    end

    return sprites
end

-- Material key might be a material itself
local function getEntityMaterialFromKey(entity, materialKey)
    local materialKeyType = utils.typeof(materialKey)
    local fromKey = entity[materialKey]
    local fromKeyType = type(fromKey)

    -- Vanilla maps might have tileset ids stored as integers
    if fromKeyType == "number" and utils.isInteger(fromKey) then
        fromKeyType = "string"
        fromKey = tostring(fromKey)
    end

    if fromKeyType == "string" and utf8.len(fromKey) == 1 then
        return fakeTilesHelper.getMaterialMatrix(entity, fromKey)

    elseif materialKeyType == "string" and utf8.len(materialKey) == 1 then
        return fakeTilesHelper.getMaterialMatrix(entity, materialKey)

    elseif materialKeyType == "matrix" then
        return materialKey
    end

    return fakeTilesHelper.getMaterialMatrix(entity, "3")
end

-- Blend mode key can also be a boolean
local function getEntityBlendMode(entity, blendModeKey)
    if type(blendModeKey) == "string" then
        return entity[blendModeKey]
    end

    return blendModeKey
end

function fakeTilesHelper.getEntitySpriteFunction(materialKey, blendKey, layer, color, x, y)
    layer = layer or "tilesFg"

    return function(room, entity, node)
        local isNode = utils.typeof(node) == "node"
        local targetX = x or isNode and node.x or entity.x or 0
        local targetY = y or isNode and node.y or entity.y or 0
        local tileX, tileY = math.floor(targetX / 8) + 1, math.floor(targetY / 8) + 1

        local material = getEntityMaterialFromKey(entity, materialKey)
        local blend = getEntityBlendMode(entity, blendKey)

        local fakeTiles = fakeTilesHelper.generateFakeTiles(room, tileX, tileY, material, layer, blend)
        local fakeTilesSprites = fakeTilesHelper.generateFakeTilesSprites(room, tileX, tileY, fakeTiles, layer, targetX, targetY, color)

        return fakeTilesSprites
    end
end

local function getMaterialCorners(entities)
    local tlx, tly = math.huge, math.huge
    local brx, bry = -math.huge, -math.huge

    for _, entity in ipairs(entities) do
        tlx = math.min(tlx, entity.x)
        tly = math.min(tly, entity.y)
        brx = math.max(brx, entity.x + entity.width)
        bry = math.max(bry, entity.y + entity.height)
    end

    return tlx, tly, brx, bry
end

function fakeTilesHelper.getCombinedMaterialMatrix(entities, materialKey, default)
    local tlx, tly, brx, bry = getMaterialCorners(entities)
    local materialWidth, materialHeight = math.ceil((brx - tlx) / 8), math.ceil((bry - tly) / 8)
    local materialMatrix = matrix.filled(default or "0", materialWidth, materialHeight)
    local fakeEntity = {
        x = tlx,
        y = tly
    }

    for _, entity in ipairs(entities) do
        local x, y = math.floor((entity.x - tlx) / 8), math.floor((entity.y - tly) / 8)
        local width, height = math.ceil(entity.width / 8), math.ceil(entity.height / 8)

        -- Vanilla maps might have tileset ids stored as integers
        local material = tostring(entity[materialKey] or "3")

        for i = 1, width do
            for j = 1, height do
                materialMatrix:set(x + i, y + j, material)
            end
        end
    end

    return materialMatrix, fakeEntity
end

function fakeTilesHelper.getCombinedEntitySpriteFunction(entities, materialKey, blendIn, layer, color, x, y)
    local materialMatrix, fakeEntity = fakeTilesHelper.getCombinedMaterialMatrix(entities, materialKey)

    return function(room)
        return fakeTilesHelper.getEntitySpriteFunction(materialMatrix, blendIn, layer, color, x, y)(room, fakeEntity)
    end
end

-- Make sure to get this in a function if used for fieldInformation, otherwise it won't update!
function fakeTilesHelper.getTilesOptions(layer)
    layer = layer or "tilesFg"

    local validTiles = brushes.getValidTiles(layer, false)
    local tileOptions = {}

    for id, path in pairs(validTiles) do
        local displayName = brushes.cleanMaterialPath(path)

        tileOptions[displayName] = id
    end

    return tileOptions
end

-- Returns a function to be up to date with any XML changes
function fakeTilesHelper.addTileFieldInformation(fieldInformation, materialKey, layer, room, entity)
    return function()
        if type(fieldInformation) == "function" then
            fieldInformation = fieldInformation(room, entity)
        end

        fieldInformation[materialKey] = {
            options = fakeTilesHelper.getTilesOptions(layer),
            editable = false
        }

        return fieldInformation
    end
end

-- Returns a function to be up to date with any XML changes
function fakeTilesHelper.getFieldInformation(materialKey, layer)
    return function()
        return {
            [materialKey] = {
                options = fakeTilesHelper.getTilesOptions(layer),
                editable = false
            }
        }
    end
end

return fakeTilesHelper