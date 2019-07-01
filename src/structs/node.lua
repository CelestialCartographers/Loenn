local nodeStruct = {}

function nodeStruct.decodeNodes(children)
    local res = {}

    for i, data <- children or {} do
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
        
        res[1] = data.x
        res[2] = data.y

        return res
    end
end

function nodeStruct.encode(node)
    local res = {}

    res.__name = "node"

    res.x = node[1]
    res.y = node[2]
   
    return res
end

return nodeStruct