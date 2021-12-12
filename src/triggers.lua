local utils = require("utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local nodeStruct = require("structs.node")

local languageRegistry = require("language_registry")

local drawing = require("utils.drawing")
local drawableFunction = require("structs.drawable_function")
local drawableRectangle = require("structs.drawable_rectangle")

local colors = require("consts.colors")
local triggerFontSize = 1

local triggers = {}

triggers.registeredTriggers = nil

-- Sets the registry to the given table (or empty one)
function triggers.initDefaultRegistry(t)
    triggers.registeredTriggers = t or {}
end

local function addHandler(handler, registerAt, filenameNoExt, filename, verbose)
    local name = handler.name or filenameNoExt

    registerAt[name] = handler

    if verbose then
        print("! Registered trigger '" .. name .. "' from '" .. filename .."'")
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

-- Returns drawable, depth
function triggers.getDrawable(name, handler, room, trigger, viewport)
    local func = function()
        local displayName = utils.humanizeVariableName(name)

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        local lineWidth = love.graphics.getLineWidth()

        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(colors.triggerBorderColor)
            love.graphics.rectangle("line", x + lineWidth / 2, y + lineWidth / 2, width - lineWidth, height - lineWidth)

            love.graphics.setColor(colors.triggerColor)
            love.graphics.rectangle("fill", x + lineWidth, y + lineWidth, width - 2 * lineWidth, height - 2 * lineWidth)

            love.graphics.setColor(colors.triggerTextColor)
            drawing.printCenteredText(displayName, x, y, width, height, font, triggerFontSize)
        end)
    end

    return drawableFunction.fromFunction(func), 0
end

local humanizedNameCache = {}

function triggers.addDrawables(batch, room, targets, viewport, yieldRate)
    local font = love.graphics.getFont()

    -- Add rectangles first, then batch draw all text

    for i, trigger in ipairs(targets) do
        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        local borderedRectangle = drawableRectangle.fromRectangle("bordered", x, y, width, height, colors.triggerColor, colors.triggerBorderColor)

        batch:addFromDrawable(borderedRectangle)

        if i % yieldRate == 0 then
            coroutine.yield(batch)
        end
    end

    local textBatch = love.graphics.newText(font)

    for i, trigger in ipairs(targets) do
        local name = trigger._name
        local displayName = humanizedNameCache[name]

        if not displayName then
            displayName = utils.humanizeVariableName(name)
            humanizedNameCache[name] = displayName
        end

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        drawing.addCenteredText(textBatch, displayName, x, y, width, height, font, triggerFontSize)
    end

    local function func()
        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(colors.triggerTextColor)
            love.graphics.draw(textBatch)
        end)
    end

    batch:addFromDrawable(drawableFunction.fromFunction(func))

    return batch
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
                        love.graphics.setColor(colors.triggerColor)
                        love.graphics.rectangle("fill", nodeX - 2, nodeY - 2, 5, 5)
                        love.graphics.rectangle("line", nodeX - 2, nodeY - 2, 5, 5)
                    end

                    previousX = nodeX
                    previousY = nodeY
                end
            end)
        end
    end
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

-- Returns all triggers of room
function triggers.getRoomItems(room, layer)
    return room.triggers
end

local function getPlacements(handler)
    return utils.callIfFunction(handler.placements)
end

local function getDefaultPlacement(handler, placements)
    return placements.default
end

local function getPlacement(placementInfo, defaultPlacement, name, handler, language)
    local placementType = "rectangle"
    local modPrefix = modHandler.getEntityModPrefix(name)
    local simpleName = string.format("%s#%s", name, placementInfo.name)
    local displayName = placementInfo.name
    local tooltipText
    local displayNameLanguage = language.triggers[name].name[placementInfo.name]
    local tooltipTextLanguage = language.triggers[name].description[placementInfo.name]

    if displayNameLanguage._exists then
        displayName = tostring(displayNameLanguage)
    end

    if tooltipTextLanguage._exists then
        tooltipText = tostring(tooltipTextLanguage)
    end

    if modPrefix then
        local modPrefixLanguage = language.mods[modPrefix].name

        if modPrefixLanguage._exists then
            displayName = string.format("%s [%s]", displayName, modPrefixLanguage)
        end
    end

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

    local placement = {
        name = simpleName,
        displayName = displayName,
        tooltipText = tooltipText,
        layer = "triggers",
        placementType = placementType,
        itemTemplate = itemTemplate
    }

    return placement
end

local function addPlacement(placementInfo, defaultPlacement, res, name, handler, language)
    table.insert(res, getPlacement(placementInfo, defaultPlacement, name, handler, language))
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

function triggers.getPlacements(layer)
    local res = {}
    local language = languageRegistry.getLanguage()

    if triggers.registeredTriggers then
        for name, handler in pairs(triggers.registeredTriggers) do
            local placements = getPlacements(handler)

            if placements then
                local defaultPlacement = getDefaultPlacement(handler, placements)

                utils.callIterateFirstIfTable(addPlacement, placements, defaultPlacement, res, name, handler, language)
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
    local guessedPlacement = guessPlacementFromData(item, name, handler) or {}
    local placement = getPlacement(guessedPlacement, name, handler, language)

    placement.itemTemplate = utils.deepcopy(item)

    return placement
end

function triggers.placeItem(room, layer, item)
    local items = triggers.getRoomItems(room, layer)

    table.insert(items, item)

    return true
end

function triggers.canResize(room, layer, trigger)
    return true, true
end

function triggers.minimumSize(room, layer, trigger)
    return 8, 8
end

function triggers.maximumSize(room, layer, trigger)
    return math.huge, math.huge
end

function triggers.nodeLimits(room, layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler and handler.nodeLimits then
        if type(handler.nodeLimits) == "function" then
            return handler.nodeLimits(room, trigger)

        else
            return unpack(handler.nodeLimits)
        end

    else
        return 0, 0
    end
end

function triggers.nodeLineRenderType(layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler and handler.nodeLineRenderType then
        return utils.callIfFunction(handler.nodeLineRenderType, trigger)

    else
        return "line"
    end
end

function triggers.nodeVisibility(layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler and handler.nodeVisibility then
        return utils.callIfFunction(handler.nodeVisibility, trigger)

    else
        return "selected"
    end
end

function triggers.ignoredFields(layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler and handler.ignoredFields then
        return utils.callIfFunction(handler.ignoredFields, trigger)

    else
        return {"_name", "_id", "originX", "originY"}
    end
end

function triggers.fieldOrder(layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler and handler.fieldOrder then
        return utils.callIfFunction(handler.fieldOrder, trigger)

    else
        return {"x", "y", "width", "height"}
    end
end

function triggers.fieldInformation(layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    local fieldInfo = {
        x = {
            fieldType = "integer",
        },
        y = {
            fieldType = "integer",
        },

        width = {
            fieldType = "integer"
        },
        height = {
            fieldType = "integer"
        }
    }

    if handler and handler.fieldInformation then
        local customFieldInformation = utils.callIfFunction(handler.fieldInformation, trigger)

        for k, v in pairs(customFieldInformation) do
            fieldInfo[k] = v
        end
    end
end

function triggers.languageData(layer, entity, language)
    local name = entity._name
    local handler = triggers.registeredTriggers[name]

    if handler and handler.languageData then
        return handler.languageData(entity)

    else
        return language.triggers[name], language.triggers.default
    end
end

triggers.initDefaultRegistry()

return triggers