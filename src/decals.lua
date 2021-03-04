local atlases = require("atlases")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local mods = require("mods")

local decals = {}

local decalsPrefix = "^decals/"

-- A frame should only be kept if it has no trailing number
-- Or if the trailing number is 0, 00, 000, ... etc
-- Using manual byte checks for performance reasons
local function keepFrame(name, removeAnimationFrames)
    if removeAnimationFrames then
        for i = #name, 1, -1 do
            local byte = string.byte(name, i, i)
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

local function hasPngExt(filename)
    return utils.fileExtension(filename) == "png"
end

function decals.getDecalNames(removeAnimationFrames, yield)
    removeAnimationFrames = removeAnimationFrames ~= false
    yield = yield ~= false

    local res = {}
    local added = {}

    -- Any loaded sprites
    for name, sprite in pairs(atlases.gameplay) do
        if name:match(decalsPrefix) then
            if keepFrame(name, removeAnimationFrames) then
                added[name] = true

                table.insert(res, name)
            end
        end
    end

    -- Mod content sprites
    -- Some of these might have already been loaded
    local modCommonPath = mods.commonModContent .. "/Graphics/Atlases/Gameplay/decals"
    local modCommonPathLength = #modCommonPath

    for i, name in ipairs(utils.getFilenames(modCommonPath, true, {}, hasPngExt)) do
        -- Remove mod common path, keep decals/ prefix
        local nameNoExt = utils.stripExtension(name)
        local resourceName = nameNoExt:sub(modCommonPathLength - 5)

        if not added[resourceName] and keepFrame(resourceName, removeAnimationFrames) then
            table.insert(res, resourceName)
        end

        if yield and i % 100 == 0 then
            coroutine.yield()
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
        local drawable = drawableSprite.spriteFromTexture(texture, decal)

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

    return drawable:getRectangle()
end

function decals.moveSelection(room, layer, selection, x, y)
    local decal = selection.item

    decal.x += x
    decal.y += y

    selection.x += x
    selection.y += y

    return true
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
        res[i] = {
            name = name,
            displayName = name,
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

function decals.placeItem(room, layer, item)
    local items = decals.getRoomItems(room, layer)

    table.insert(items, item)

    return true
end

-- Returns all decals of room
function decals.getRoomItems(room, layer)
    return layer == "decalsFg" and room.decalsFg or room.decalsBg
end

return decals