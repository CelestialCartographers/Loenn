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
    if handler.sprite then
        local sprites = handler.sprite(room, entity, viewport)

        if sprites then
            if #sprites == 0 and utils.typeof(sprites) == "drawableSprite" then
                return sprites, sprites.depth

            else
                for j, sprite in ipairs(sprites) do
                    if utils.typeof(sprite) == "drawableSprite" then
                        return sprite, sprite.depth
                    end
                end
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

-- Returns all entities of room
function entities.getRoomItems(room, layer)
    return room.entities
end

entities.initDefaultRegistry()

return entities