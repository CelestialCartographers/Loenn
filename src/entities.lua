local utils = require("utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")
local drawing = require("drawing")
local nodeStruct = require("structs.node")

local languageRegistry = require("language_registry")

local drawableSprite = require("structs.drawable_sprite")
local drawableFunction = require("structs.drawable_function")
local drawableRectangle = require("structs.drawable_rectangle")

local missingTextureName = modHandler.internalModContent .. "/missing_image"

local colors = require("colors")

local entities = {}

local missingEntity = require("defaults.viewer.entity")

local entityRegisteryMT = {
    __index = function() return missingEntity end
}

entities.registeredEntities = nil

-- Sets the registry to the given table (or empty one) and sets the missing entity metatable
function entities.initDefaultRegistry(t)
    entities.registeredEntities = setmetatable(t or {}, entityRegisteryMT)
end

local function addHandler(handler, registerAt, filenameNoExt, filename, verbose)
    local name = handler.name or filenameNoExt

    registerAt[name] = handler

    if verbose then
        print("! Registered entity '" .. name .. "' from '" .. filename .."'")
    end
end

function entities.registerEntity(filename, registerAt, verbose)
    -- Use verbose flag or default to logPluginLoading from config
    verbose = verbose or verbose == nil and configs.debug.logPluginLoading
    registerAt = registerAt or entities.registeredEntities

    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)

    utils.callIterateFirstIfTable(addHandler, handler, registerAt, filenameNoExt, filename, verbose)
end

function entities.loadEntities(path, registerAt)
    pluginLoader.loadPlugins(path, registerAt, entities.registerEntity)
end

function entities.loadInternalEntities(registerAt)
    return entities.loadEntities("entities", registerAt)
end

function entities.loadExternalEntities(registerAt)
    local filenames = modHandler.findPlugins("entities")

    return entities.loadEntities(filenames, registerAt)
end

-- Returns default depth
function entities.getDefaultDepth(name, handler, room, entity, viewport)
    return utils.callIfFunction(handler.depth, room, entity, viewport) or 0
end

local function addAutomaticDrawableFields(handler, drawable, room, entity, isNode)
    local justificationKey = isNode and "nodeJustification" or "justification"
    local scaleKey = isNode and "nodeScale" or "scale"
    local offsetKey = isNode and "nodeOffset" or "offset"
    local rotationKey = isNode and "nodeRotation" or "rotation"
    local colorKey = isNode and "nodeColor" or "color"

    if handler[justificationKey] then
        if type(handler[justificationKey]) == "function" then
            drawable:setJustification(handler[justificationKey](room, entity))

        else
            drawable:setJustification(unpack(handler[justificationKey]))
        end
    end

    if handler[scaleKey] then
        if type(handler[scaleKey]) == "function" then
            drawable:setScale(handler[scaleKey](room, entity))

        else
            drawable:setScale(unpack(handler[scaleKey]))
        end
    end

    if handler[offsetKey] then
        if type(handler[offsetKey]) == "function" then
            drawable:setOffset(handler[offsetKey](room, entity))

        else
            drawable:setOffset(unpack(handler[offsetKey]))
        end
    end

    if handler[rotationKey] then
        drawable[rotationKey] = utils.callIfFunction(handler[rotationKey], room, entity)
    end

    if handler[colorKey] then
        drawable[colorKey] = utils.callIfFunction(handler[colorKey] or handler, room, entity)
    end
end

-- Returns drawable, depth
function entities.getEntityDrawable(name, handler, room, entity, viewport)
    handler = handler or entities.registeredEntities[name]

    if handler.sprite then
        local sprites = handler.sprite(room, entity, viewport)

        if sprites then
            if #sprites == 0 and utils.typeof(sprites) == "drawableSprite" then
                return sprites, sprites.depth

            else
                return sprites, nil
            end
        end

    elseif handler.texture then
        local texture = utils.callIfFunction(handler.texture, room, entity)
        local drawable = drawableSprite.fromTexture(texture, entity)

        if drawable then
            addAutomaticDrawableFields(handler, drawable, room, entity, false)

        else
            drawable = drawableSprite.fromTexture(missingTextureName, entity)

            if configs.editor.warnOnMissingTexture then
                print(string.format("Could not find texture '%s' for entity '%s' in room '%s'", texture, entity._name, room.name))
            end
        end

        return drawable

    elseif handler.draw then
        return drawableFunction.fromFunction(handler.draw, room, entity, viewport)

    elseif handler.rectangle or entity.width and entity.height then
        local rectangle

        if handler.rectangle then
            rectangle = handler.rectangle(room, entity, viewport)

        else
            rectangle = utils.rectangle(entity.x, entity.y, entity.width, entity.height)
        end

        -- If both fillColor and borderColor is specified then make a rectangle with these
        if handler.fillColor and handler.borderColor then
            local drawableSprites = drawableRectangle.fromRectangle("bordered", rectangle, handler.fillColor, handler.borderColor):getDrawableSprite()

            return drawableSprites

        else
            local drawable = drawableRectangle.fromRectangle(handler.mode or "fill", rectangle, handler.color or colors.default)

            return drawable
        end
    end
end

function entities.getNodeDrawable(name, handler, room, entity, node, nodeIndex, viewport)
    handler = handler or entities.registeredEntities[name]

    if handler.nodeSprite then
        local sprites = handler.nodeSprite(room, entity, node, nodeIndex, viewport)

        if sprites then
            if #sprites == 0 and utils.typeof(sprites) == "drawableSprite" then
                return sprites, sprites.depth, false

            else
                return sprites, nil, false
            end
        end

    elseif handler.nodeTexture then
        local texture = utils.callIfFunction(handler.nodeTexture, room, entity, node, nodeIndex, viewport)
        local drawable = drawableSprite.fromTexture(texture, node)

        addAutomaticDrawableFields(handler, drawable, room, entity, true)

        return drawable, nil, false

    elseif handler.nodeDraw then
        return drawableFunction.fromFunction(handler.nodeDraw, room, entity, node, nodeIndex, viewport)

    else
        -- Make a copy of entity and change the position to the node
        -- This makes it correctly render and select at the node rather than main entity

        local entityCopy = table.shallowcopy(entity)

        entityCopy.x = node.x
        entityCopy.y = node.y

        return entities.getEntityDrawable(name, handler, room, entityCopy, viewport), nil, true
    end
end

function entities.getDrawable(name, handler, room, entity, viewport)
    handler = handler or entities.registeredEntities[name]

    local nodeVisibility = entities.nodeVisibility("entities", entity)
    local entityDrawable, depth = entities.getEntityDrawable(name, handler, room, entity, viewport)

    -- Add node drawable(s) if the entity asks for it
    if entity.nodes and nodeVisibility == "always" then
        if utils.typeof(entityDrawable) ~= "table" then
            entityDrawable = {entityDrawable}
        end

        for i, node in ipairs(entity.nodes) do
            local nodeDrawable = entities.getNodeDrawable(name, handler, room, entity, node, i, viewport)

            if nodeDrawable then
                if utils.typeof(nodeDrawable) == "table" then
                    for _, drawable in ipairs(nodeDrawable) do
                        table.insert(entityDrawable, drawable)
                    end

                else
                    table.insert(entityDrawable, nodeDrawable)
                end
            end
        end
    end

    return entityDrawable, depth
end

local function getSpriteRectangle(drawables)
    -- TODO - Inline coverRectangles?
    -- Check if this is expensive enough in larger rooms

    local rectangles = {}

    for i, drawable in ipairs(drawables) do
        if drawable.getRectangle then
            rectangles[i] = drawable:getRectangle()

            if drawable.ignoreRest then
                break
            end
        end
    end

    local x, y, width, height = utils.coverRectangles(rectangles)

    return utils.rectangle(x, y, width, height)
end

function entities.getNodeRectangles(room, entity, viewport)
    local name = entity._name
    local handler = entities.registeredEntities[name]
    local nodes = entity.nodes

    if not nodes then
        return nil
    end

    local rectangles = {}

    local x, y = entity.x or 0, entity.y or 0

    for i, node in ipairs(nodes) do
        if handler.nodeRectangle then
            rectangles[i] = handler.nodeRectangle(room, entity, node, i)

        else
            local nodeDrawable, nodeDepth, usedMainEntityDrawable = entities.getNodeDrawable(name, handler, room, entity, node, i, viewport)
            local nodeRectangle

            if nodeDrawable then
                -- Some extra logic if the drawable is from the entity rather than node functions
                if usedMainEntityDrawable then
                    if handler.rectangle then
                        nodeRectangle = handler.rectangle(room, entity)

                        -- Offset to node position rather than entity
                        nodeRectangle.x = x - node.x
                        nodeRectangle.y = y - node.y

                    elseif entity.width and entity.height then
                        nodeRectangle = utils.rectangle(node.x or 0, node.y or 0, entity.width, entity.height)
                    end

                elseif #nodeDrawable > 0 then
                    nodeRectangle = getSpriteRectangle(nodeDrawable)

                else
                    nodeRectangle = nodeDrawable:getRectangle()
                end

                table.insert(rectangles, utils.deepcopy(nodeRectangle))
            end
        end
    end

    return rectangles
end

-- Returns main entity selection rectangle, then table of node rectangles
function entities.getSelection(room, entity, viewport)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.selection then
        return handler.selection(room, entity)

    elseif handler.rectangle then
        return handler.rectangle(room, entity), entities.getNodeRectangles(room, entity)

    elseif entity.width and entity.height then
        return utils.rectangle(entity.x or 0, entity.y or 0, entity.width, entity.height), entities.getNodeRectangles(room, entity)

    else
        local drawable = entities.getEntityDrawable(name, handler, room, entity)
        local nodeRectangles = entities.getNodeRectangles(room, entity)

        if drawable then
            if #drawable == 0 and drawable.getRectangle then
                return drawable:getRectangle(), nodeRectangles

            else
                return getSpriteRectangle(drawable), nodeRectangles
            end
        end
    end
end

-- TODO - Implement in more performant way?
function entities.drawSelected(room, layer, entity, color)
    color = color or colors.selectionCompleteNodeLineColor

    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.drawSelected then
        return handler.drawSelected(room, layer, entity, color)

    else
        local x, y = entity.x or 0, entity.y or 0
        local halfWidth, halfHeight = (entity.width or 0) / 2, (entity.height or 0) / 2
        local nodes = entity.nodes

        if nodes and #nodes > 0 then
            local nodeVisibility = entities.nodeVisibility(layer, entity)
            local nodeLineRenderType = entities.nodeLineRenderType(layer, entity)

            local entityRenderX, entityRenderY = x + halfWidth, y + halfHeight
            local previousX, previousY = entityRenderX, entityRenderY

            for i, node in ipairs(nodes) do
                local nodeDrawable = entities.getNodeDrawable(name, handler, room, entity, node, i)

                if nodeDrawable then
                    if nodeLineRenderType then
                        local nodeX, nodeY = node.x or 0, node.y or 0
                        local nodeRenderX, nodeRenderY = nodeX + halfWidth, nodeY + halfHeight

                        drawing.callKeepOriginalColor(function()
                            love.graphics.setColor(color)

                            if nodeLineRenderType == "line" then
                                love.graphics.line(previousX, previousY, nodeRenderX, nodeRenderY)

                            elseif nodeLineRenderType == "fan" then
                                love.graphics.line(entityRenderX, entityRenderY, nodeX, nodeY)
                            end
                        end)

                        previousX = nodeRenderX
                        previousY = nodeRenderY
                    end

                    if nodeVisibility == "selected" then
                        if #nodeDrawable > 0 then
                            for _, drawable in ipairs(nodeDrawable) do
                                if drawable.x and drawable.y then
                                    drawable:draw()
                                end
                            end

                        else
                            if nodeDrawable.x and nodeDrawable.y then
                                nodeDrawable:draw()
                            end
                        end
                    end
                end
            end
        end
    end
end

function entities.moveSelection(room, layer, selection, x, y)
    local entity, node = selection.item, selection.node
    local name = entity._name
    local handler = entities.registeredEntities[name]

    -- Notify movement
    if handler.onMove then
        handler.onMove(room, entity, node, x, y)
    end

    -- Custom entity movement
    if handler.move then
        handler.move(room, entity, node, x, y)

    else
        if node == 0 then
            entity.x += x
            entity.y += y

        else
            local nodes = entity.nodes

            if nodes and node <= #nodes then
                local target = nodes[node]

                target.x += x
                target.y += y
            end
        end
    end

    -- Custom selection movement if needed after custom move
    if handler.updateSelection then
        handler.updateSelection(room, entity, node, selection, x, y, selection.width, selection.height)

    else
        selection.x += x
        selection.y += y
    end

    return true
end

function entities.deleteSelection(room, layer, selection)
    local targets = entities.getRoomItems(room, layer)
    local target, node = selection.item, selection.node
    local name = target._name
    local handler = entities.registeredEntities[name]
    local minimumNodes, maximumNodes = entities.nodeLimits(room, layer, target)

    for i, entity in ipairs(targets) do
        if entity == target then
            local nodes = entity.nodes

            -- Delete entity if deleting a node gives it too few nodes
            -- Set node to 0 to move deletion target from node to entity itself
            if nodes and node > 0 then
                local nodeCount = #nodes

                if minimumNodes and minimumNodes ~= -1 and nodeCount - 1 < minimumNodes then
                    node = 0
                end
            end

            -- Notify deletion
            if handler.onDelete then
                handler.onDelete(room, entity, node)
            end

            -- Custom deletion
            if handler.delete then
                return handler.delete(room, entity, node)

            else
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
    end

    return false
end

function entities.addNodeToSelection(room, layer, selection)
    local targets = entities.getRoomItems(room, layer)
    local target, node = selection.item, selection.node
    local name = target._name
    local handler = entities.registeredEntities[name]
    local minimumNodes, maximumNodes = entities.nodeLimits(room, layer, target)

    for i, entity in ipairs(targets) do
        if entity == target then
            local nodes = entity.nodes or nodeStruct.decodeNodes({})

            -- Make sure we don't add more nodes than supported
            if #nodes >= maximumNodes and maximumNodes ~= -1 then
                return false
            end

            if not entity.nodes then
                entity.nodes = nodes
            end

            -- Notify addition
            if handler.onNodeAdded then
                handler.onNodeAdded(room, entity, node)
            end

            -- Custom node adding
            if handler.nodeAdded then
                return handler.nodeAdded(room, entity, node)

            else
                if node == 0 then
                    local nodeX = entity.x + (entity.width or 0) + 8
                    local nodeY = entity.y

                    table.insert(nodes, 1, {x = nodeX, y = nodeY})

                else
                    local nodeX = nodes[node].x + (entity.width or 0) + 8
                    local nodeY = nodes[node].y

                    table.insert(nodes, node + 1, {x = nodeX, y = nodeY})
                end

                return true
            end
        end
    end

    return false
end

local function guessPlacementType(name, handler, placement)
    if placement and placement.data then
        if placement.data.width or placement.data.height then
            return "rectangle"
        end

        if placement.data.nodes then
            return "line"
        end
    end

    local fakeEntity = {_name = name}
    local minimumNodes, maximumNodes = entities.nodeLimits(nil, nil, fakeEntity)

    if minimumNodes == 1 and maximumNodes == 1 then
        return "line"
    end

    return "point"
end

local function addPlacement(placement, res, name, handler, language)
    local placementType = placement.placementType or guessPlacementType(name, handler, placement)
    local modPrefix = modHandler.getEntityModPrefix(name)
    local simpleName = string.format("%s#%s", name, placement.name)
    local displayName = placement.name
    local tooltipText
    local displayNameLanguage = language.entities[name].name[placement.name]
    local tooltipTextLanguage = language.entities[name].description[placement.name]

    if displayNameLanguage._exists then
        displayName = tostring(displayNameLanguage)
    end

    if tooltipTextLanguage._exists then
        tooltipText = tostring(tooltipTextLanguage)
    end

    if modPrefix then
        local modPrefixLanguage = language.mods[modPrefix].name

        if modPrefixLanguage._exists then
            displayName = string.format("%s (%s)", displayName, modPrefixLanguage)
        end
    end

    local itemTemplate = {
        _name = name,
        _id = 0
    }

    if placement.data then
        for k, v in pairs(placement.data) do
            itemTemplate[k] = v
        end
    end

    itemTemplate.x = itemTemplate.x or 0
    itemTemplate.y = itemTemplate.y or 0

    table.insert(res, {
        name = simpleName,
        displayName = displayName,
        tooltipText = tooltipText,
        layer = "entities",
        placementType = placementType,
        itemTemplate = itemTemplate
    })
end

function entities.getPlacements(layer)
    local res = {}
    local language = languageRegistry.getLanguage()

    if entities.registeredEntities then
        for name, handler in pairs(entities.registeredEntities) do
            local placements = utils.callIfFunction(handler.placements)

            if placements then
                utils.callIterateFirstIfTable(addPlacement, placements, res, name, handler, language)
            end
        end
    end

    return res
end

function entities.placeItem(room, layer, item)
    local items = entities.getRoomItems(room, layer)

    table.insert(items, item)

    return true
end

function entities.canResize(room, layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.canResize then
        if type(handler.canResize) == "function" then
            return handler.canResize(room, entity)

        else
            return unpack(handler.canResize)
        end

    else
        return entity.width ~= nil, entity.height ~= nil
    end
end

function entities.minimumSize(room, layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.minimumSize then
        if type(handler.minimumSize) == "function" then
            return handler.minimumSize(room, entity)

        else
            return unpack(handler.minimumSize)
        end
    end
end

function entities.nodeLimits(room, layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler and handler.nodeLimits then
        if type(handler.nodeLimits) == "function" then
            return handler.nodeLimits(room, entity)

        else
            return unpack(handler.nodeLimits)
        end

    else
        return 0, 0
    end
end

function entities.nodeLineRenderType(layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler and handler.nodeLineRenderType then
        return utils.callIfFunction(handler.nodeLineRenderType, entity)

    else
        return false
    end
end

function entities.nodeVisibility(layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler and handler.nodeVisibility then
        return utils.callIfFunction(handler.nodeVisibility, entity)

    else
        return "selected"
    end
end

function entities.ignoredFields(layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler and handler.ignoredFields then
        return utils.callIfFunction(handler.ignoredFields, entity)

    else
        return {"_name", "_id", "originX", "originY"}
    end
end

function entities.fieldOrder(layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler and handler.fieldOrder then
        return utils.callIfFunction(handler.fieldOrder, entity)

    else
        local fields = {"x", "y"}

        if entity.width ~= nil then
            table.insert(fields, "width")
        end

        if entity.height ~= nil then
            table.insert(fields, "height")
        end

        return fields
    end
end

function entities.fieldInformation(layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

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
        local customFieldInformation = utils.callIfFunction(handler.fieldInformation, entity)

        for k, v in pairs(customFieldInformation) do
            fieldInfo[k] = v
        end
    end

    return fieldInfo
end

function entities.languageData(layer, entity, language)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler and handler.languageData then
        return handler.languageData(entity)

    else
        return language.entities[name], language.entities.default
    end
end

-- Returns all entities of room
function entities.getRoomItems(room, layer)
    return room.entities
end

entities.initDefaultRegistry()

return entities