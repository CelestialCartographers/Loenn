local atlases = require("atlases")
local drawableSprite = require("structs.drawable_sprite")
local utils = require("utils")
local mods = require("mods")

local decals = {}

local zipFileNamesCache = {}
local zipFileNamesNoAnimationsCache = {}

local decalsPrefix = "decals/"
local gameplayPath = "Graphics/Atlases/Gameplay"
local decalsPath = "Graphics/Atlases/Gameplay/decals"

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

function decals.getDecalNamesFromMod(modFolder, removeAnimationFrames, yield, names, associatedMods, added)
    names = names or {}
    associatedMods = associatedMods or {}

    local loadedModInfo = mods.loadedMods[modFolder]
    local canCache = loadedModInfo.zipFile
    local cachableNames = {}
    local cacheTarget = removeAnimationFrames and zipFileNamesCache or zipFileNamesNoAnimationsCache

    local filenames = mods.findModFolderFiletype(modFolder, {}, decalsPath, "png")
    local decalPathLength = #decalsPath

    local modSpecificPath = string.format(mods.specificModContent, modFolder)
    local modMetadata = mods.getModMetadataFromPath(modSpecificPath)
    local modAssociatedMods = false

    if modMetadata then
        modAssociatedMods = mods.getModNamesFromMetadata(modMetadata)
    end

    if canCache and cacheTarget[modFolder] then
        local cachedNames = cacheTarget[modFolder]

        for _, name in ipairs(cachedNames) do
            if not added[resourceName] then
                added[name] = true

                table.insert(names, name)
                table.insert(associatedMods, modAssociatedMods)
            end
        end

        return names, associatedMods
    end

    if yield then
        coroutine.yield()
    end

    for i, name in ipairs(filenames) do
        if not added[name] then
            local nameNoExt, ext = utils.splitExtension(name)

            if ext == "png" then
                local shouldKeepFrame = keepFrame(nameNoExt, removeAnimationFrames)

                if shouldKeepFrame then
                    -- Remove mod specific path, keep decals/ prefix
                    local firstSlashIndex = utils.findCharacter(nameNoExt, "/")
                    local resourceName = nameNoExt:sub(firstSlashIndex + decalPathLength - 5)

                    if not added[resourceName] then
                        added[resourceName] = true

                        table.insert(names, resourceName)
                        table.insert(associatedMods, modAssociatedMods)

                        if canCache then
                            table.insert(cachableNames, resourceName)
                        end
                    end
                end
            end

            if yield and i % 100 == 0 then
                coroutine.yield()
            end
        end
    end

    if canCache then
        cacheTarget[modFolder] = cachableNames
    end

    return names, associatedMods
end

function decals.getDecalNames(specificMods, removeAnimationFrames, yield)
    removeAnimationFrames = removeAnimationFrames ~= false
    yield = yield ~= false

    local names = {}
    local associatedMods = {}
    local added = {}

    local specificModsLookup = {}

    if specificMods then
        specificModsLookup = table.flip(specificMods)
    end

    -- Any internal sprites, these are from vanilla
    for name, sprite in pairs(atlases.gameplay) do
        if type(sprite) == "table" and sprite.internalFile then
            if utils.startsWith(name, decalsPrefix) and keepFrame(name, removeAnimationFrames) then
                added[name] = true
                added[sprite.meta.filename] = true

                table.insert(names, name)
                table.insert(associatedMods, false)
            end
        end
    end

    -- Figure out which mod folders we should load
    for modFolder, metadata in pairs(mods.modMetadata) do
        local modNames = mods.getModNamesFromMetadata(metadata)
        local useModResources = not specificMods

        if not useModResources and modNames then
            for _, modName in ipairs(modNames) do
                if specificModsLookup[modName] then
                    useModResources = true

                    break
                end
            end
        end

        if useModResources then
            decals.getDecalNamesFromMod(modFolder, removeAnimationFrames, yield, names, associatedMods, added)
        end
    end

    return names, associatedMods
end

function decals.getDrawable(texture, handler, room, decal, viewport)
    local meta = atlases.gameplay[texture]

    local x = decal.x or 0
    local y = decal.y or 0

    local scaleX = decal.scaleX or 1
    local scaleY = decal.scaleY or 1

    local rotation = math.rad(decal.rotation or 0)

    if meta then
        local drawable = drawableSprite.fromTexture(texture, decal)

        drawable.rotation = rotation
        drawable:setScale(scaleX, scaleY)
        drawable:setJustification(0.5, 0.5)

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

function decals.resizeSelection(room, layer, selection, offsetX, offsetY, directionX, directionY)
    local decal = selection.item

    if offsetX < 0 then
        decal.scaleX = math.max(decal.scaleX / 2, 1.0)

    elseif offsetX > 0 then
        decal.scaleX = math.min(decal.scaleX * 2, 2^4)
    end

    if offsetY < 0 then
        decal.scaleY = math.max(decal.scaleY / 2, 1.0)

    elseif offsetY > 0 then
        decal.scaleY = math.min(decal.scaleY * 2, 2^4)
    end

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

function decals.getPlacements(layer, specificMods)
    local names = {}
    local names, fromMods = decals.getDecalNames(specificMods)

    for i, name in ipairs(names) do
        local nameNoDecalsPrefix = name:sub(8)
        local itemTemplate = {
            texture = name,

            x = 0,
            y = 0,

            scaleX = 1,
            scaleY = 1,

            rotation = 0
        }

        names[i] = {
            name = name,
            displayName = nameNoDecalsPrefix,
            layer = layer,
            placementType = "point",
            itemTemplate = itemTemplate,
            associatedMods = fromMods[i]
        }
    end

    return names
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
    return {"x", "y", "scaleX", "scaleY", "texture", "rotation"}
end

function decals.languageData(language, layer, decal)
    return language.decals
end

function decals.associatedMods(decal, layer)
    -- Make sure we don't load the image from disk!
    local texture = decal.texture
    local sprite = rawget(atlases.gameplay, texture)

    -- Sprites that are loaded already have the associated mods data
    if sprite then
        -- Skip internal files, they don't belong to a mod
        if sprite.internalFile then
            return
        end

        return sprite.associatedMods

    else
        local fullFilename = string.format("%s/%s/%s.png", mods.commonModContent, gameplayPath, texture)
        local modMetadata = mods.getModMetadataFromPath(fullFilename)

        if modMetadata then
            return mods.getModNamesFromMetadata(modMetadata)
        end
    end
end

return decals