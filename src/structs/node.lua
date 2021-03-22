local nodeStruct = {}

function nodeStruct.decodeNodes(children)
    local res = {
        _type = "nodes"
    }

    for i, data in ipairs(children or {}) do
        local node = nodeStruct.decode(data)

        if node then
            table.insert(res, node)
        end
    end

    return res
end

function nodeStruct.decode(data)
    if data.__name == "node" then
        local res = {
            _type = "node"
        }

        res.x = data.x
        res.y = data.y

        return res
    end
end

function nodeStruct.encode(node)
    local res = {}

    res.__name = "node"

    res.x = node.x
    res.y = node.y

    return res
end

return nodeStruct