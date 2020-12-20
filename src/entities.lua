local utils = require("utils")
local tasks = require("task")

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

function entities.registerEntity(fn, registerAt)
    registerAt = registerAt or entities.registeredEntities

    local pathNoExt = utils.stripExtension(fn)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt

    print("! Registered entity '" .. name .. "' for '" .. name .."'")

    registerAt[name] = handler
end

-- TODO - Santize user paths
function entities.loadInternalEntities(registerAt, path)
    registerAt = registerAt or entities.registeredEntities
    path = path or "entities"

    for i, file <- love.filesystem.getDirectoryItems(path) do
        -- Always use Linux paths here
        entities.registerEntity(utils.joinpath(path, file):gsub("\\", "/"), registerAt)

        tasks.yield()
    end

    tasks.update(registerAt)
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

        if drawable.getRectangle then
            return drawable:getRectangle(), nil
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
                nodes[node][1] += x
                nodes[node][2] += y
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

    for i, entity in ipairs(targets) do
        if entity == target then
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
                    local nodes = entity.nodes

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
    -- TODO - Implement

    return "point"
end

local function addPlacement(res, name, handler, placement)
    local placementType = placement.placementType or guessPlacementType(name, handler, placement)
    local itemTemplate = {
        _name = name,
        _id = 0 --TODO
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
        displayName = placement.name,
        layer = "entities",
        placementType = placementType,
        itemTemplate = itemTemplate
    })
end

function entities.getPlacements(layer)
    local res = {}

    if entities.registeredEntities then
        for name, handler in pairs(entities.registeredEntities) do
            local placements = utils.callIfFunction(handler.placements)

            if placements then
                if #placements > 0 then
                    for _, placement in ipairs(placements) do
                        addPlacement(res, name, handler, placement)
                    end

                else
                    addPlacement(res, name, handler, placements)
                end
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

-- Returns all entities of room
function entities.getRoomItems(room, layer)
    return room.entities
end

entities.initDefaultRegistry()

return entities