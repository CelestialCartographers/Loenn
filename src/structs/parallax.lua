local parallaxStruct = {}

function parallaxStruct.decode(data)
    local res = {
        _type = "parallax"
    }

    for k, v in pairs(data or {}) do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end

    return res
end

function parallaxStruct.encode(parallax)
    local res = {}

    for k, v in pairs(parallax) do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end

    res.__name = "parallax"

    return res
end

return parallaxStruct