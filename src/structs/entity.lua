local nodeStruct = require("structs/node")

local entityStruct = {}

-- Special cases
local ignoredAttrs = {
    __children = true,
    __name = true,
    id = true,
    originX = true,
    originY = true,

    _name = true,
    _id = true,
    nodes = true,
    _raw = true,
    _type = true
}

function entityStruct.decode(data)
    local entity = {
        _type = "entity",
        _raw = data
    }

    entity._name = data.__name
    entity._id = data.id

    for k, v <- data do
        if not ignoredAttrs[k] then
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

    for k, v <- entity do
        if not ignoredAttrs[k] then
            res[k] = v
        end
    end

    if entity.nodes then
        res.__children = {}

        for i, node <- entity.nodes do
            table.insert(res.__children, nodeStruct.encode(node))
        end
    end

    return res
end

return entityStruct