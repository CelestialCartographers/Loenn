local snapshot = {}

function snapshot.create(description, data, backward, forward)
    local res = {
        _type = "snapshot"
    }

    res.description = description
    res.data = data
    res.backward = data.backward or backward
    res.forward = data.forward or forward

    return res
end

return snapshot