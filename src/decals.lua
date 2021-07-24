local atlases = require("atlases")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local mods = require("mods")

local decals = {}

local decalsPrefix = "decals/"
local decalFolderPath = "/Graphics/Atlases/Gameplay/decals"

-- A frame should only be kept if it has no trailing number
-- Or if the trailing number is 0, 00, 000, ... etc
-- Using manual byte checks for performance reasons
local function keepFrame(name, removeAnimationFrames)
    if removeAnimationFrames then
        for i = #name, 1, -1 do
            local byte = name:byte(i, i)
            local isNumber = byte >= 48 and byte <= 57

            if isNumber then
                local isZero = byte == 48

                if not isZero then
                    return false
                end

            else
                return true
            end
        end
    end

    return true
end

function decals.getDecalNames(removeAnimationFrames, yield)
    removeAnimationFrames = removeAnimationFrames ~= false
    yield = yield ~= false

    local res = {}
    local added = {}

    -- Any loaded sprites
    for name, sprite in pairs(atlases.gameplay) do
        if utils.startsWith(name, decalsPrefix) then
            if keepFrame(name, removeAnimationFrames) then
                added[name] = true
                added[sprite.meta.filename] = true

                table.insert(res, name)
            end
        end
    end

    -- Mod content sprites
    -- Some of these might have already been loaded
    local modCommonPath = mods.commonModContent .. decalFolderPath
    local modCommonPathLength = #modCommonPath
    local filenames = mods.findModFiletype(decalFolderPath, "png")

    for i, name in ipairs(filenames) do
        if not added[name] then
            local nameNoExt, ext = utils.stripExtension(name)
            local shouldKeepFrame = keepFrame(nameNoExt, removeAnimationFrames)

            if shouldKeepFrame then
                -- Remove mod common path, keep decals/ prefix
                local resourceName = nameNoExt:sub(modCommonPathLength - 5)

                if not added[resourceName] then
                    table.insert(res, resourceName)
                end
            end

            if yield and i % 100 == 0 then
                coroutine.yield()
            end
        end
    end

    return res
end

function decals.getDrawable(texture, handler, room, decal, viewport)
    local meta = atlases.gameplay[texture]

    local x = decal.x or 0
    local y = decal.y or 0

    local scaleX = decal.scaleX or 1
    local scaleY = decal.scaleY or 1

    if meta then
        local drawable = drawableSprite.fromTexture(texture, decal)

        drawable:setScale(scaleX, scaleY)
        drawable:setJustification(0, 0)
        drawable:setOffset(0, 0)
        drawable:setPosition(
            x - meta.offsetX * scaleX - math.floor(meta.realWidth / 2) * scaleX,
            y - meta.offsetY * scaleY - math.floor(meta.realHeight / 2) * scaleY
        )

        return drawable
    end
end

function decals.getSelection(room, decal)
    local drawable = decals.getDrawable(decal.texture, nil, room, decal, nil)

    if drawable then
        return drawable:getRectangle()

    else
        return utils.rectangle(decal.x - 2, decal.y - 2, 5, 5)
    end
end

function decals.moveSelection(room, layer, selection, x, y)
    local decal = selection.item

    decal.x += x
    decal.y += y

    selection.x += x
    selection.y += y

    return true
end

function decals.flipSelection(room, layer, selection, horizontal, vertical)
    local decal = selection.item

    if horizontal then
        decal.scaleX *= -1
    end

    if vertical then
        decal.scaleY *= -1
    end

    return horizontal or vertical
end

function decals.deleteSelection(room, layer, selection)
    local targets = decals.getRoomItems(room, layer)
    local target = selection.item

    for i, decal in ipairs(targets) do
        if decal == target then
            table.remove(targets, i)

            return true
        end
    end

    return false
end

function decals.getPlacements(layer)
    local res = {}
    local names = decals.getDecalNames()

    for i, name in ipairs(names) do
        local nameNoDecalsPrefix = name:sub(8)

        res[i] = {
            name = name,
            displayName = nameNoDecalsPrefix,
            layer = layer,
            placementType = "point",
            itemTemplate = {
                texture = name,

                x = 0,
                y = 0,

                scaleX = 1,
                scaleY = 1
            }
        }
    end

    return res
end

function decals.cloneItem(room, layer, item)
    local texture = item.texture
    local textureNoDecalPrefix = texture:sub(8)

    local placement = {
        name = texture,
        displayName = textureNoDecalPrefix,
        layer = layer,
        placementType = "point",
        itemTemplate = utils.deepcopy(item)
    }

    return placement
end

function decals.placeItem(room, layer, item)
    local items = decals.getRoomItems(room, layer)

    table.insert(items, item)

    return true
end

-- Returns all decals of room
function decals.getRoomItems(room, layer)
    return layer == "decalsFg" and room.decalsFg or room.decalsBg
end

function decals.ignoredFields(layer, decal)
    return {}
end

function decals.fieldOrder(layer, decal)
    return {"x", "y", "scaleX", "scaleY", "texture"}
end

function decals.languageData(layer, decal, language)
    return language.decals
end


return decals