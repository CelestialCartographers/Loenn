local effectStruct = {}

function effectStruct.decode(data)
    res = {
        _type = "effect",
        _raw = data
    }

    res._name = data.__name -- Keep types consistent, store effect name in _name instead
    
    for k, v <- data or {} do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end

    return res
end

function effectStruct.encode(effect)
    local res = {}

    for k, v <- effect do
        res[k] = v
    end

    res._type = nil
    res.__name = res._name
    res._name = nil

    return res
end

return effectStruct