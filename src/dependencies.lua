-- TODO - Improve localization support

local mods = require("mods")
local layerHandlers = require("layer_handlers")
local parallaxHandler = require("parallax")
local effectHandler = require("effects")
local utils = require("utils")
local languageRegistry = require("language_registry")

local dependencyFinder = {}

local analyzeLayers = {
    "decalsFg",
    "decalsBg",
    "entities",
    "triggers"
}

local function localizeModName(modName, language)
    local language = language or languageRegistry.getLanguage()
    local modNameLanguage = language.mods[modName].name

    if modNameLanguage._exists then
        return tostring(modNameLanguage)
    end

    return modName
end

local function localizeCategoryName(category, language)
    -- Try dependency specific first, fall back to layer names

    local language = language or languageRegistry.getLanguage()
    local categoryNameLanguage = language.dependencies.category[category]
    local layerNameLanguage = language.layers.name[category]

    if categoryNameLanguage._exists then
        return tostring(categoryNameLanguage)
    end

    if layerNameLanguage._exists then
        return tostring(layerNameLanguage)
    end

    return category
end

local function localizeFilenameReason(filename, language)
    local language = language or languageRegistry.getLanguage()
    local reasonFormatString = tostring(language.dependencies.foundModFile)

    return string.format(reasonFormatString, filename)
end

local function addAssociatedMods(path, associated, reason, modNames)
    if not associated then
        return modNames
    end

    local associatedType = type(associated)
    local parts = $(path):split(".")()

    if associatedType == "string" then
        local localizedModName = associated--localizeModName(associated)
        local target = utils.getPath(modNames, {localizedModName}, {}, true)
        local reasons = utils.getPath(target, parts, {}, true)

        table.insert(reasons, reason)

    elseif associatedType == "table" then
        for _, name in ipairs(associated) do
            local localizedModName = name--localizeModName(name)
            local target = utils.getPath(modNames, {localizedModName}, {}, true)
            local reasons = utils.getPath(target, parts, {}, true)

            table.insert(reasons, reason)
        end
    end

    return modNames
end

local function modsForFilename(filename)
    if not filename then
        return
    end

    local commonFilename = string.format("%s/%s", mods.commonModContent, filename)
    local modMetadata = mods.getModMetadataFromPath(commonFilename)
    local modNames = mods.getModNamesFromMetadata(modMetadata)

    return modNames
end

local function addAssociatedModsFromFilename(path, filename, modNames)
    if filename then
        local associated = modsForFilename(filename)
        local localizedReason = localizeFilenameReason(filename)

        addAssociatedMods(path, associated, localizedReason, modNames)
    end
end

function dependencyFinder.analyzeSide(side)
    map = side and side.map or side

    local modNames = {}

    dependencyFinder.analyzeMetadata(side.meta, modNames)

    dependencyFinder.analyzeStylegrounds(map.stylesFg, modNames)
    dependencyFinder.analyzeStylegrounds(map.stylesBg, modNames)

    for _, room in ipairs(map.rooms or {}) do
        dependencyFinder.analyzeRoom(room, modNames)
    end

    return modNames
end

function dependencyFinder.analyzeMetadata(metadata, modNames)
    modNames = modNames or {}

    local language = languageRegistry.getLanguage()
    local localizedCategory = localizeCategoryName("metadata")

    -- TODO - Tileset paths

    local iconFilename = metadata.Icon and string.format("Graphics/Atlases/Gui/%s.png", metadata.Icon)

    addAssociatedModsFromFilename(localizedCategory, metadata.ForegroundTiles, modNames)
    addAssociatedModsFromFilename(localizedCategory, metadata.BackgroundTiles, modNames)
    addAssociatedModsFromFilename(localizedCategory, metadata.AnimatedTiles, modNames)
    addAssociatedModsFromFilename(localizedCategory, metadata.Portraits, modNames)
    addAssociatedModsFromFilename(localizedCategory, metadata.Sprites, modNames)
    addAssociatedModsFromFilename(localizedCategory, iconFilename, modNames)

    return modNames
end

function dependencyFinder.analyzeStylegrounds(styles, modNames)
    modNames = modNames or {}

    for _, style in ipairs(styles) do
        dependencyFinder.analyzeStyle(style, modNames)
    end

    return modNames
end

function dependencyFinder.analyzeStyle(style, modNames, language)
    language = language or languageRegistry.getLanguage()
    modNames = modNames or {}

    local styleType = utils.typeof(style)

    if styleType == "parallax" then
        local associated = parallaxHandler.associatedMods(style)
        local localizedCategory = localizeCategoryName("parallax")
        local localizedReason = parallaxHandler.displayName(language, style)

        addAssociatedMods(localizedCategory, associated, localizedReason, modNames)

    elseif styleType == "effect" then
        local localizedCategory = localizeCategoryName("effect")
        local associated = effectHandler.associatedMods(style)
        local localizedReason = effectHandler.displayName(language, style)

        addAssociatedMods(localizedCategory, associated, localizedReason, modNames)

    elseif styleType == "apply" then
        for _, child in ipairs(style.children or {}) do
            dependencyFinder.analyzeStyle(child, modNames, language)
        end
    end

    return modNames
end

function dependencyFinder.analyzeRoomLayer(room, layer, modNames)
    modNames = modNames or {}

    local handler = layerHandlers.getHandler(layer)

    if handler then
        local items = handler.getRoomItems(room, layer)

        for _, item in ipairs(items) do
            dependencyFinder.analyzeRoomLayerItem(handler, room, layer, item, modNames)
        end
    end

    return modNames
end

function dependencyFinder.analyzeRoomLayerItem(handler, room, layer, item, modNames)
    modNames = modNames or {}

    if handler.associatedMods then
        local language = languageRegistry.getLanguage()
        local layerReasonFormatString = tostring(language.dependencies.layerItemReason)
        local associated = handler.associatedMods(item, layer)
        local reason = string.format(layerReasonFormatString, item._name or item.texture, room.name, item.x or 0, item.y or 0)
        local localizedLayerName = localizeCategoryName(layer, language)

        addAssociatedMods(localizedLayerName, associated, reason, modNames)
    end

    return modNames
end

function dependencyFinder.analyzeRoom(room, modNames)
    modNames = modNames or {}

    for _, layer in ipairs(analyzeLayers) do
        dependencyFinder.analyzeRoomLayer(room, layer, modNames)
    end

    return modNames
end

function dependencyFinder.getDependencyModNames(modMetadata, addSelf)
    local dependedOnMods = {}

    for _, metadata in ipairs(modMetadata) do
        if addSelf ~= false and metadata.Name then
            dependedOnMods[metadata.Name] = true
        end

        for _, dependency in ipairs(metadata.Dependencies or {}) do
            if dependency.Name then
                local localizedName = mod

                dependedOnMods[dependency.Name] = true
            end
        end
    end

    return dependedOnMods
end

return dependencyFinder