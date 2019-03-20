local fillerStruct = {}

function fillerStruct.decode(data)
    local filler = {
        _type = "filler",
        _raw = data
    }

    filler.x = data.x or 0
    filler.y = data.y or 0

    filler.width = data.w or 0
    filler.height = data.h or 0

    return filler
end

function fillerStruct.encode(rect)
    local res = {}

    res.__name = "rect"

    res.x = rect.x
    res.y = rect.y

    res.w = rect.width
    res.h = rect.height

    return res
end

return fillerStruct