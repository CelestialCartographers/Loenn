local entityStruct = {}

local ignoredAttrs = {
    __children = true,
    __name = true,
    id = true,
    originX = true,
    originY = true
}

function entityStruct.getNodes(entity)
    local res = $()

    for i, node <- entity.__children or {} do
        if node.__name == "node" then
            res += {
                node.x,
                node.y
            }
        end
    end

    return res
end

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

    if data.__children and data.__children:len > 0 then
        entity.nodes = entityStruct.getNodes(data)
    end

    return entity
end

function entityStruct.encode(entity)

end

return entityStruct