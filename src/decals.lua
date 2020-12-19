local atlases = require("atlases")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")

local decals = {}

local decalsPrefix = "^decals/"
local decalFrameSuffix = "%d*$"

-- A frame should only be kept if it has no trailing number
-- Or if the trailing number is 0, 00, 000, ... etc
local function keepFrame(name)
    local numberSuffix = name:match(decalFrameSuffix)

    for i = 1, #numberSuffix do
        if numberSuffix:sub(i, i) ~= "0" then
            return false
        end
    end

    return true
end

function decals.getDecalNames(removeFrames)
    removeFrames = removeFrames == nil or removeFrames

    local res = {}

    for name, sprite in pairs(atlases.gameplay) do
        if name:match(decalsPrefix) then
            if not removeFrames or keepFrame(name) then
                table.insert(res, name)
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

-- Returns all decals of room
function decals.getRoomItems(room, layer)
    return layer == "decalsFg" and room.decalsFg or room.decalsBg
end

return decals