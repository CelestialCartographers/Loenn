local nodeStruct = require("structs.node")

local triggerStruct = {}

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

function triggerStruct.decode(data)
    local trigger = {
        _type = "trigger",
        _raw = data
    }

    trigger._name = data.__name
    trigger._id = data.id

    for k, v in pairs(data) do
        if not ignoredAttrs[k] then
            trigger[k] = v
        end
    end

    if data.__children and #data.__children > 0 then
        trigger.nodes = nodeStruct.decodeNodes(data.__children)
    end

    return trigger
end

function triggerStruct.encode(trigger)
    local res = {}

    res.__name = trigger._name
    res.id = trigger._id

    for k, v in pairs(trigger) do
        if not ignoredAttrs[k] then
            res[k] = v
        end
    end

    if trigger.nodes then
        res.__children = {}

        for i, node in ipairs(trigger.nodes) do
            table.insert(res.__children, nodeStruct.encode(node))
        end
    end

    return res
end

return triggerStruct