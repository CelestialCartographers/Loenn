local utils = require("utils")
local pluginLoader = require("plugin_loader")
local modHandler = require("mods")
local configs = require("configs")

local languageRegistry = require("language_registry")

local drawableSprite = require("structs.drawable_sprite")
local drawableFunction = require("structs.drawable_function")
local drawableRectangle = require("structs.drawable_rectangle")

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

-- Returns drawable, depth
function entities.getDrawable(name, handler, room, entity, viewport)
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
        local drawable = drawableSprite.spriteFromTexture(texture, entity)

        return drawable

    elseif handler.rectangle then
        local rectangle = handler.rectangle(room, entity, viewport)
        local drawable = drawableRectangle.fromRectangle(handler.mode or "fill", handler.color or colors.default, rectangle)

        return drawable

    elseif handler.draw then
        return drawableFunction.fromFunction(handler.draw, room, entity, viewport)
    end
end

-- Returns main entity selection rectangle, then table of node rectangles
-- TODO - Implement nodes
function entities.getSelection(room, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.selection then
        return handler.selection(room, entity)

    elseif handler.rectangle then
        return handler.rectangle(room, entity), nil

    else
        local drawable = entities.getDrawable(name, handler, room, entity)

        if #drawable == 0 and utils.typeof(drawable) == "drawableSprite" then
            return drawable:getRectangle(), nil

        else
            local rectangles = {}

            for i, draw in ipairs(drawable) do
                rectangles[i] = draw:getRectangle()
            end

            local x, y, width, height = utils.coverRectangles(rectangles)

            return utils.rectangle(x, y, width, height), nil
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
    local displayName = placement.name
    local displayNameLanguage = language.entities[name].placements[placement.name]

    if displayNameLanguage._exists then
        displayName = tostring(displayNameLanguage)
    end

    if modPrefix then
        local modPrefixLanguage = language.mods[modPrefix].name

        if modPrefixLanguage._exists then
            displayName = string.format("%s (%s)", displayName, tostring(modPrefixLanguage))
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
        name = name,
        displayName = displayName,
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
        return handler.canResize(room, entity)

    else
        return entity.width ~= nil, entity.height ~= nil
    end
end

function entities.minimumSize(room, layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.minimumSize then
        return handler.minimumSize(room, entity)
    end
end

function entities.nodeLimits(room, layer, entity)
    local name = entity._name
    local handler = entities.registeredEntities[name]

    if handler.nodeLimits then
        return handler.nodeLimits(room, entity)

    else
        return 0, 0
    end
end

-- Returns all entities of room
function entities.getRoomItems(room, layer)
    return room.entities
end

entities.initDefaultRegistry()

return entities