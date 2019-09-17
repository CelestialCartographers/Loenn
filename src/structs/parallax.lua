local parallaxStruct = {}

function parallaxStruct.decode(data)
    res = {
        _type = "parallax",
        _raw = data
    }
    
    for k, v <- data or {} do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end

    return res
end

function parallaxStruct.encode(parallax)
    local res = {}

    for k, v <- parallax do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end

    res.__name = "parallax"

    return res
end

return parallaxStruct