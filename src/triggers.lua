local utils = require("utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local nodeStruct = require("structs.node")
local logging = require("logging")
local depths = require("consts.object_depths")
local loadedState = require("loaded_state")
local modificationWarner = require("modification_warner")
local subLayers = require("sub_layers")

local languageRegistry = require("language_registry")

local drawing = require("utils.drawing")
local drawableRectangle = require("structs.drawable_rectangle")
local drawableText = require("structs.drawable_text")

local colors = require("consts.colors")

local triggers = {}

local missingTriggerHandler = require("defaults.viewer.undefined_trigger")

local triggerRegisteryMT = {
    __index = function() return missingTriggerHandler end
}

triggers.triggerFontSize = 1
triggers.registeredTriggers = nil

-- Sets the registry to the given table (or empty one)
function triggers.initDefaultRegistry(t)
    triggers.registeredTriggers = setmetatable(t or {}, triggerRegisteryMT)
end

local function addHandler(handler, registerAt, filenameNoExt, filename, verbose)
    if type(handler) ~= "table" then
        return
    end

    local name = handler.name or filenameNoExt
    local modMetadata = modHandler.getModMetadataFromPath(filename)

    handler._loadedFrom = filename
    handler._loadedFromModName = modHandler.getModNamesFromMetadata(modMetadata)

    registerAt[name] = handler

    if verbose then
        logging.info("Registered trigger '" .. name .. "' from '" .. filename .."'")
    end
end

function triggers.registerTrigger(filename, registerAt, verbose)
    -- Use verbose flag or default to logPluginLoading from config
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading
    registerAt = registerAt or triggers.registeredTriggers

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")
    local handler = utils.rerequire(pathNoExt)

    utils.callIterateFirstIfTable(addHandler, handler, registerAt, filenameNoExt, filename, verbose)
end

function triggers.loadTriggers(path, registerAt)
    pluginLoader.loadPlugins(path, registerAt, triggers.registerTrigger)
end

function triggers.loadInternalTriggers(registerAt)
    return triggers.loadTriggers("triggers", registerAt)
end

function triggers.loadExternalTriggers(registerAt)
    local filenames = modHandler.findPlugins("triggers")

    return triggers.loadTriggers(filenames, registerAt)
end

local humanizedNameCache = {}
local humanizedNameTrimmedModNameCache = {}

function triggers.getDrawableDisplayText(trigger)
    local name = trigger._name
    local trimModName = configs.editor.triggersTrimModName
    local cache = trimModName and humanizedNameTrimmedModNameCache or humanizedNameCache
    local displayName = cache[name]

    if not displayName then
        -- Humanize data name and then remove " Trigger" at the end if possible
        -- Remove mod name if trimming is enabled

        displayName = name

        if trimModName then
            displayName = string.match(displayName, "^.-/(.*)") or displayName
        end

        displayName = utils.humanizeVariableName(displayName)
        displayName = string.match(displayName, "(.-) Trigger$") or displayName

        cache[name] = displayName
    end

    return displayName
end

function triggers.getCategory(trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler.category then
        local category = utils.callIfFunction(handler.category, trigger)

        return category or "general"
    end

    return "general"
end

function triggers.triggerColor(room, trigger)
    local useCategoryColors = configs.editor.triggersUseCategoryColors

    if not useCategoryColors then
        return colors.triggerColor, colors.triggerBorderColor
    end

    local category = triggers.getCategory(trigger)

    local triggerColor = colors.triggerColorCategory[category] or colors.triggerColor
    local triggerBorderColor = colors.triggerBorderColorCategory[category] or colors.triggerBorderColor
    local triggerTextColor = colors.triggerTextColor

    return triggerColor, triggerBorderColor, triggerTextColor
end

function triggers.triggerText(room, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]
    local fallbackText = triggers.getDrawableDisplayText(trigger)

    if handler.triggerText then
        if utils.isCallable(handler.triggerText) then
            return handler.triggerText(room, trigger) or fallbackText

        else
            return handler.triggerText or fallbackText
        end
    end

    return fallbackText
end

-- Returns drawable, depth
function triggers.getDrawable(name, handler, room, trigger, viewport)
    local displayName = triggers.triggerText(room, trigger)

    local x = trigger.x or 0
    local y = trigger.y or 0

    local width = trigger.width or 16
    local height = trigger.height or 16

    local fillColor, borderColor, textColor = triggers.triggerColor(room, trigger)
    local borderedRectangle = drawableRectangle.fromRectangle("bordered", x, y, width, height, fillColor, borderColor)
    local textDrawable = drawableText.fromText(displayName, x, y, width, height, nil, triggers.triggerFontSize, textColor)

    local drawables = borderedRectangle:getDrawableSprite()
    table.insert(drawables, textDrawable)

    textDrawable.depth = depths.triggers - 1

    return drawables, depths.triggers
end

-- Returns main trigger selection rectangle, then table of node rectangles
function triggers.getSelection(room, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    local mainRectangle = utils.rectangle(trigger.x, trigger.y, trigger.width, trigger.height)
    local nodeRectangles = {}

    local nodes = trigger.nodes

    if nodes then
        for i, node in ipairs(nodes) do
            local x, y = node.x, node.y

            nodeRectangles[i] = utils.rectangle(x - 2, y - 2, 5, 5)
        end
    end

    return mainRectangle, nodeRectangles
end

function triggers.drawSelected(room, layer, trigger, color)
    color = color or colors.selectionCompleteNodeLineColor

    local x, y = trigger.x or 0, trigger.y or 0
    local width, height = trigger.width or 0, trigger.height or 0
    local halfWidth, halfHeight = width / 2, height / 2
    local nodes = trigger.nodes

    if nodes and #nodes > 0 then
        local triggerRenderX, triggerRenderY = x + halfWidth, y + halfHeight
        local previousX, previousY = triggerRenderX, triggerRenderY
        local nodeLineRenderType = triggers.nodeLineRenderType(layer, trigger)
        local nodeVisibility = triggers.nodeVisibility(layer, trigger)
        local renderNodes = nodeVisibility == "selected"

        if nodeLineRenderType or renderNodes then
            drawing.callKeepOriginalColor(function()
                for _, node in ipairs(nodes) do
                    local nodeX, nodeY = node.x or 0, node.y or 0

                    if nodeLineRenderType then
                        love.graphics.setColor(color)

                        if nodeLineRenderType == "line" then
                            love.graphics.line(previousX, previousY, nodeX, nodeY)

                        elseif nodeLineRenderType == "fan" then
                            love.graphics.line(triggerRenderX, triggerRenderY, nodeX, nodeY)
                        end
                    end

                    if renderNodes then
                        local triggerColor, triggerBorderColor = triggers.triggerColor(room, trigger)

                        love.graphics.setColor(triggerColor)
                        love.graphics.rectangle("fill", nodeX - 2, nodeY - 2, 5, 5)

                        love.graphics.setColor(triggerBorderColor)
                        love.graphics.rectangle("line", nodeX - 2, nodeY - 2, 5, 5)
                    end

                    previousX = nodeX
                    previousY = nodeY
                end
            end)
        end
    end
end

local function updateSelectionNaive(room, trigger, node, selection)
    local rectangle, nodeRectangles = triggers.getSelection(room, trigger)
    local newSelectionRectangle = node == 0 and rectangle or nodeRectangles and nodeRectangles[node]

    if newSelectionRectangle then
        selection.x = newSelectionRectangle.x
        selection.y = newSelectionRectangle.y

        selection.width = newSelectionRectangle.width
        selection.height = newSelectionRectangle.height
    end
end

function triggers.areaFlipSelection(room, layer, selection, horizontal, vertical, area)
    local trigger, node = selection.item, selection.node
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    local target = trigger
    local width = trigger.width or 0
    local height = trigger.height or 0

    if selection.node > 0 then
        local nodes = trigger.nodes

        if nodes and node <= #nodes then
            target = nodes[node]

        else
            return false
        end
    end

    if horizontal then
        target.x = 2 * area.x + area.width - width - target.x
    end

    if vertical then
        target.y = 2 * area.y + area.height - height - target.y
    end

    updateSelectionNaive(room, trigger, node, selection)

    return horizontal or vertical
end

function triggers.moveSelection(room, layer, selection, offsetX, offsetY)
    local trigger, node = selection.item, selection.node

    if node == 0 then
        trigger.x += offsetX
        trigger.y += offsetY

    else
        local nodes = trigger.nodes

        if nodes and node <= #nodes then
            local target = nodes[node]

            target.x += offsetX
            target.y += offsetY
        end
    end

    selection.x += offsetX
    selection.y += offsetY

    return true
end

-- Negative offsets means we are growing up/left, should move the selection as well as changing size
function triggers.resizeSelection(room, layer, selection, offsetX, offsetY, directionX, directionY)
    local trigger, node = selection.item, selection.node

    if node ~= 0 or offsetX == 0 and offsetY == 0 then
        return false
    end

    local canHorizontal, canVertical = triggers.canResize(room, layer, trigger)
    local minimumWidth, minimumHeight = triggers.minimumSize(room, layer, trigger)
    local maximumWidth, maximumHeight = triggers.maximumSize(room, layer, trigger)

    local oldWidth, oldHeight = trigger.width or 0, trigger.height or 0
    local newWidth, newHeight = oldWidth, oldHeight
    local madeChanges = false

    if offsetX ~= 0 and canHorizontal then
        newWidth += offsetX * math.abs(directionX)

        if minimumWidth <= newWidth and newWidth <= maximumWidth then
            trigger.width = newWidth
            selection.width = newWidth

            if directionX < 0 then
                trigger.x -= offsetX
                selection.x -= offsetX
            end

            madeChanges = true
        end
    end

    if offsetY ~= 0 and canVertical then
        newHeight += offsetY * math.abs(directionY)

        if minimumHeight <= newHeight and newHeight <= maximumHeight then
            trigger.height = newHeight
            selection.height = newHeight

            if directionY < 0 then
                trigger.y -= offsetY
                selection.y -= offsetY
            end

            madeChanges = true
        end
    end

    return madeChanges
end

function triggers.deleteSelection(room, layer, selection)
    local targets = triggers.getRoomItems(room, layer)
    local target, node = selection.item, selection.node
    local minimumNodes, maximumNodes = triggers.nodeLimits(room, layer, target)

    for i, trigger in ipairs(targets) do
        if trigger == target then
            local nodes = trigger.nodes

            -- Delete trigger if deleting a node gives it too few nodes
            -- Set node to 0 to move deletion target from node to trigger itself
            if nodes and node > 0 then
                local nodeCount = #nodes

                if minimumNodes and minimumNodes ~= -1 and nodeCount - 1 < minimumNodes then
                    node = 0
                end
            end
            if node == 0 then
                table.remove(targets, i)

            else
                if nodes then
                    table.remove(nodes, node)
                end
            end

            return true
        end
    end

    return false
end

function triggers.addNodeToSelection(room, layer, selection)
    local targets = triggers.getRoomItems(room, layer)
    local target, node = selection.item, selection.node
    local minimumNodes, maximumNodes = triggers.nodeLimits(room, layer, target)

    for i, trigger in ipairs(targets) do
        if trigger == target then
            local nodes = trigger.nodes or nodeStruct.decodeNodes({})

            -- Make sure we don't add more nodes than supported
            if #nodes >= maximumNodes and maximumNodes ~= -1 then
                return false
            end

            if not trigger.nodes then
                trigger.nodes = nodes
            end

            if node == 0 then
                local nodeX = trigger.x + (trigger.width or 0) + 8
                local nodeY = trigger.y

                table.insert(nodes, 1, {x = nodeX, y = nodeY})

            else
                local nodeX = nodes[node].x + (trigger.width or 0) + 8
                local nodeY = nodes[node].y

                table.insert(nodes, node + 1, {x = nodeX, y = nodeY})
            end

            return true
        end
    end

    return false
end

function triggers.ignoredSimilarityKeys(trigger)
    local handler = triggers.getHandler(trigger)
    local ignoredSimilarityKeys = handler and handler.ignoredSimilarityKeys

    if ignoredSimilarityKeys then
        return utils.callIfFunction(ignoredSimilarityKeys, trigger)
    end

    return {"_name", "_id", "_type", "originX", "originY", "x", "y"}
end

function triggers.selectionsSimilar(selectionA, selectionB, strict)
    local triggerA = selectionA.item
    local triggerB = selectionB.item
    local sameTriggerType = triggerA._name == triggerB._name

    if strict and sameTriggerType then
        local keyCountA = utils.countKeys(triggerA)
        local keyCountB = utils.countKeys(triggerB)

        if keyCountA ~= keyCountB then
            return false
        end

        local ignoredKeys = table.flip(triggers.ignoredSimilarityKeys(triggerA))

        for k, v in pairs(triggerA) do
            if not ignoredKeys[k] and v ~= triggerB[k] then
                return false
            end
        end
    end

    return sameTriggerType
end

-- Returns all triggers of room
function triggers.getRoomItems(room, layer)
    return room.triggers
end

local function selectionRenderFilterPredicate(room, layer, subLayer,  trigger)
    local hiddenCategories = loadedState.getLayerInformation("triggers", "hiddenCategories")

    if hiddenCategories then
        local category = triggers.getCategory(trigger)

        if hiddenCategories[category] then
            return false
        end
    end

    local triggerSubLayer = trigger._editorLayer or 0

    if subLayer and subLayer ~= -1 then
        if subLayer ~= triggerSubLayer then
            return false
        end
    end

    -- Render check
    if not subLayer then
        return subLayers.getShouldLayerRender(layer, triggerSubLayer)
    end

    return true
end

function triggers.selectionFilterPredicate(room, layer, subLayer, trigger)
    return selectionRenderFilterPredicate(room, layer, subLayer, trigger)
end

function triggers.renderFilterPredicate(room, trigger)
    return selectionRenderFilterPredicate(room, "triggers", nil, trigger)
end

local function getPlacements(handler)
    return utils.callIfFunction(handler.placements)
end

local function getDefaultPlacement(handler, placements)
    if placements then
        return placements.default
    end
end

local function getPlacementLanguage(language, triggerName, name, key, default)
    local result = language.triggers[triggerName].placements[key][name]

    if result._exists then
        return tostring(result)
    end

    return default
end

local function getAlternativeDisplayNames(placementInfo, name, language)
    local alternativeName = placementInfo.alternativeName
    local alternativeNameType = type(alternativeName)

    if alternativeNameType == "string" then
        local displayName = getPlacementLanguage(language, name, alternativeName, "name")

        if displayName then
            return {displayName}
        end

    elseif alternativeNameType == "table" then
        local result = {}

        for _, altName in ipairs(alternativeName) do
            local displayName = getPlacementLanguage(language, name, altName, "name")

            if displayName then
                table.insert(result, displayName)
            end
        end

        if #result > 0 then
            return result
        end
    end
end

local function getPlacement(placementInfo, defaultPlacement, name, handler, language)
    local placementType = "rectangle"
    local modPrefix = modHandler.getEntityModPrefix(name)
    local simpleName = string.format("%s#%s", name, placementInfo.name)
    local placementName = placementInfo.name
    local displayName = getPlacementLanguage(language, name, placementName, "name", placementInfo.name)
    local tooltipText = getPlacementLanguage(language, name, placementName, "description")
    local alternativeDisplayNames = getAlternativeDisplayNames(placementInfo, name, language)

    local itemTemplate = {
        _name = name,
        _id = 0
    }

    if defaultPlacement and defaultPlacement.data then
        for k, v in pairs(defaultPlacement.data) do
            itemTemplate[k] = v
        end
    end

    if placementInfo.data then
        for k, v in pairs(placementInfo.data) do
            itemTemplate[k] = v
        end
    end

    itemTemplate.x = itemTemplate.x or 0
    itemTemplate.y = itemTemplate.y or 0

    itemTemplate.width = itemTemplate.width or 16
    itemTemplate.height = itemTemplate.height or 16

    local associatedMods = placementInfo.associatedMods or triggers.associatedMods(itemTemplate)
    local modsString = modHandler.formatAssociatedMods(language, associatedMods)
    local displayNameNoMods = displayName

    if modsString then
        displayName = string.format("%s %s", displayName, modsString)
    end

    local placement = {
        name = simpleName,
        displayName = displayName,
        displayNameNoMods = displayNameNoMods,
        alternativeDisplayNames = alternativeDisplayNames,
        tooltipText = tooltipText,
        layer = "triggers",
        placementType = placementType,
        itemTemplate = itemTemplate,
        associatedMods = associatedMods
    }

    return placement
end

local function addPlacement(placementInfo, defaultPlacement, res, name, handler, language, specificMods)
    local placement = getPlacement(placementInfo, defaultPlacement, name, handler, language)

    -- Check if this placement should be ignored
    -- Always keep vanilla and Everest
    if specificMods and placement.associatedMods then
        local lookup = table.flip(placement.associatedMods)

        for _, specific in ipairs(specificMods) do
            if lookup[specific] then
                table.insert(res, placement)

                return
            end
        end

    else
        table.insert(res, placement)
    end
end

-- TODO - Make more sophisticated? Works for now
local function guessPlacementFromData(item, name, handler)
    local placements = utils.callIfFunction(handler.placements)

    if placements then
        if #placements > 0 then
            return placements[1]

        else
            return placements
        end
    end
end

function triggers.getPlacements(layer, specificMods)
    local res = {}
    local language = languageRegistry.getLanguage()

    if triggers.registeredTriggers then
        for name, handler in pairs(triggers.registeredTriggers) do
            local placements = getPlacements(handler)

            if placements then
                local defaultPlacement = getDefaultPlacement(handler, placements)

                utils.callIterateFirstIfTable(addPlacement, placements, defaultPlacement, res, name, handler, language, specificMods)
            end
        end
    end

    return res
end

-- We don't know which placement this is from, but getPlacement does most of the job for us
function triggers.cloneItem(room, layer, item)
    local name = item._name
    local handler = triggers.registeredTriggers[name]
    local language = languageRegistry.getLanguage()

    local placements = utils.callIfFunction(handler.placements)
    local defaultPlacement = getDefaultPlacement(handler, placements)
    local guessedPlacement = guessPlacementFromData(item, name, handler) or {}
    local placement = getPlacement(guessedPlacement, defaultPlacement, name, handler, language)

    placement.itemTemplate = utils.deepcopy(item)

    return placement
end

function triggers.placeItem(room, layer, item)
    local items = triggers.getRoomItems(room, layer)

    table.insert(items, item)

    return true
end

function triggers.getHandler(trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    return handler
end

-- All extra arguments considered default value
-- Specifically for functions that need both entity and room
-- Will unpack returned tables, do not use for functions that actually want table returns
function triggers.getHandlerValue(trigger, room, key, ...)
    local handler = triggers.getHandler(trigger)

    if not handler then
        return ...
    end

    local handlerValue = handler[key]

    if handlerValue then
        return utils.unpackIfTable(utils.callIfFunction(handlerValue, room, trigger))
    end

    return ...
end

function triggers.canResize(room, layer, trigger)
    return true, true
end

function triggers.minimumSize(room, layer, trigger)
    return 1, 1
end

function triggers.maximumSize(room, layer, trigger)
    return math.huge, math.huge
end

function triggers.warnBelowSize(room, layer, trigger)
    return 8, 8
end

function triggers.warnAboveSize(room, layer, trigger)
    return math.huge, math.huge
end

function triggers.nodeLimits(room, layer, trigger)
    return triggers.getHandlerValue(trigger, room, "nodeLimits", 0, 0)
end

function triggers.nodeLineRenderType(layer, trigger)
    local handler = triggers.getHandler(trigger)

    if handler and handler.nodeLineRenderType then
        return utils.callIfFunction(handler.nodeLineRenderType, trigger)
    end

    return "line"
end

function triggers.nodeVisibility(layer, trigger)
    local handler = triggers.getHandler(trigger)

    if handler and handler.nodeVisibility then
        return utils.callIfFunction(handler.nodeVisibility, trigger)
    end

    return "selected"
end

local alwaysIgnoredFields = {"_name", "_id", "originX", "originY", "_fromLayer", "_editorLayer"}
local alwaysIgnoredFieldsMultiple = utils.concat(alwaysIgnoredFields, {"x", "y", "width", "height", "nodes"})

function triggers.ignoredFields(layer, trigger)
    local handler = triggers.getHandler(trigger)
    local ignoredFields = handler and handler.ignoredFields

    if ignoredFields then
        local ignored = utils.callIfFunction(ignoredFields, trigger)

        return utils.concat(ignored, alwaysIgnoredFields)
    end

    return alwaysIgnoredFields
end

function triggers.ignoredFieldsMultiple(layer, trigger)
    local handler = triggers.getHandler(trigger)
    local ignoredFieldsMultiple = handler and handler.ignoredFieldsMultiple

    if ignoredFieldsMultiple then
        local ignored = utils.callIfFunction(ignoredFieldsMultiple, trigger)

        return utils.concat(ignored, alwaysIgnoredFieldsMultiple)
    end

    return alwaysIgnoredFieldsMultiple
end

function triggers.fieldOrder(layer, trigger)
    local defaultFieldOrder = {"x", "y", "width", "height"}
    local handler = triggers.getHandler(trigger)

    if handler and handler.fieldOrder then
        return utils.callIfFunction(handler.fieldOrder, trigger)
    end

    return defaultFieldOrder
end

function triggers.fieldInformation(layer, trigger)
    local handler = triggers.getHandler(trigger)

    local minimumWidth, minimumHeight = triggers.minimumSize(nil, layer, trigger)
    local maximumWidth, maximumHeight = triggers.maximumSize(nil, layer, trigger)
    local warnBelowWidth, warnBelowHeight = triggers.warnBelowSize(nil, layer, trigger)
    local warnAboveWidth, warnAboveHeight = triggers.warnAboveSize(nil, layer, trigger)

    local fieldInfo = {
        x = {
            fieldType = "integer",
        },
        y = {
            fieldType = "integer",
        },

        width = {
            fieldType = "integer",
            minimumValue = minimumWidth,
            maximumValue = maximumWidth,
            warningBelowValue = warnBelowWidth,
            warningAboveValue = warnAboveWidth
        },
        height = {
            fieldType = "integer",
            minimumValue = minimumHeight,
            maximumValue = maximumHeight,
            warningBelowValue = warnBelowHeight,
            warningAboveValue = warnAboveHeight
        }
    }

    if handler and handler.fieldInformation then
        local customFieldInformation = utils.callIfFunction(handler.fieldInformation, trigger)

        for k, v in pairs(customFieldInformation) do
            fieldInfo[k] = v
        end
    end

    return fieldInfo
end

function triggers.languageData(language, layer, trigger)
    local name = trigger._name
    local handler = triggers.getHandler(trigger)

    if handler and handler.languageData then
        return handler.languageData(trigger)
    end

    return language.triggers[name], language.triggers.default
end

function triggers.associatedMods(trigger, layer)
    local handler = triggers.getHandler(trigger)

    if handler then
        if handler.associatedMods then
            return utils.callIfFunction(handler.associatedMods, trigger)
        end

        -- Fallback to mod containing the plugin
        return handler._loadedFromModName
    end
end

triggers.initDefaultRegistry()

modificationWarner.addModificationWarner(triggers)

return triggers