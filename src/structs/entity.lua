-- Chosing to load originX and originY, even if the values are completely unused
-- Noel confirms that it is left over from Ogmo editor, and most likely isn't used for any entities/triggers
-- For now, Lönn (like Ahorn) will simply not include these values in newly placed entities

local nodeStruct = require("structs.node")

local entityStruct = {}

-- Special cases
local ignoredDecodingAttrs = {
    __children = true,
    __name = true,
    id = true,
}

local ignoredEncodingAttrs = {
    _name = true,
    _id = true,
    nodes = true,
    _type = true
}

function entityStruct.decode(data)
    local entity = {
        _type = "entity"
    }

    entity._name = data.__name
    entity._id = data.id

    for k, v in pairs(data) do
        if not ignoredDecodingAttrs[k] then
            entity[k] = v
        end
    end

    if data.__children and #data.__children > 0 then
        entity.nodes = nodeStruct.decodeNodes(data.__children)
    end

    return entity
end

function entityStruct.encode(entity)
    local res = {}

    res.__name = entity._name
    res.id = entity._id

    for k, v in pairs(entity) do
        if not ignoredEncodingAttrs[k] then
            res[k] = v
        end
    end

    if entity.nodes then
        res.__children = {}

        for _, node in ipairs(entity.nodes) do
            table.insert(res.__children, nodeStruct.encode(node))
        end
    end

    -- Do not save editor layer 0, it is the fallback
    if res._editorLayer == 0 then
        res._editorLayer = nil
    end

    return res
end

return entityStruct