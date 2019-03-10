local entity_struct = {}

local ignored_attrs = {
    __children = true,
    __name = true,
    id = true,
    originX = true,
    originY = true
}

function entity_struct.get_nodes(entity)
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

function entity_struct.decode(data)
    local entity = {
        _type = "entity",
        _raw = data
    }

    entity._name = data.__name
    entity._id = data.id

    for k, v <- data do
        if not ignored_attrs[k] then
            entity[k] = v
        end
    end

    if data.__children and data.__children:len > 0 then
        entity.nodes = entity_struct.get_nodes(data)
    end

    return entity
end

function entity_struct.encode(entity)

end

return entity_struct