local trigger_struct = {}

local ignored_attrs = {
    __children = true,
    __name = true,
    id = true,
    originX = true,
    originY = true
}

function trigger_struct.get_nodes(trigger)
    local res = $()

    for i, node <- trigger.__children or {} do
        if node.__name == "node" then
            res += {
                node.x,
                node.y
            }
        end
    end

    return res
end

function trigger_struct.decode(data)
    local trigger = {
        _type = "trigger",
        _raw = data
    }

    trigger._name = data.__name
    trigger._id = data.id

    for k, v <- data do
        if not ignored_attrs[k] then
            trigger[k] = v
        end
    end

    if data.__children and #data.__children > 0 then
        trigger.nodes = trigger_struct.get_nodes(data)
    end

    return trigger
end

function trigger_struct.encode(trigger)

end

return trigger_struct