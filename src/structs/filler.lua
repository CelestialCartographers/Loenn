local filler_struct = {}

function filler_struct.decode(data)
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

function filler_struct.encode(data)

end

return filler_struct