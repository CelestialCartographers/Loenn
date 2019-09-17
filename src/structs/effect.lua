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
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end

    res.__name = effect._name

    return res
end

return effectStruct