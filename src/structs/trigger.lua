local triggerStruct = {}

local ignoredAttrs = {
    __children = true,
    __name = true,
    id = true,
    originX = true,
    originY = true
}

function triggerStruct.getNodes(trigger)
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

function triggerStruct.decode(data)
    local trigger = {
        _type = "trigger",
        _raw = data
    }

    trigger._name = data.__name
    trigger._id = data.id

    for k, v <- data do
        if not ignoredAttrs[k] then
            trigger[k] = v
        end
    end

    if data.__children and #data.__children > 0 then
        trigger.nodes = triggerStruct.getNodes(data)
    end

    return trigger
end

function triggerStruct.encode(trigger)

end

return triggerStruct