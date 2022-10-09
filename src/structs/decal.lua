local decalStruct = {}

-- Replace \ with /, remove .png and prefix with `decals/`
function decalStruct.decodeDecalTexture(texture)
    return "decals/" .. texture:gsub("\\", "/"):sub(1, #texture - 4)
end

-- Strip decals/ and add .png
function decalStruct.encodeDecalTexture(texture)
    return texture:match("^decals/(.*)") .. ".png"
end

function decalStruct.decode(data)
    local decal = {
        _type = "decal"
    }

    decal.texture = decalStruct.decodeDecalTexture(data.texture or "")

    decal.x = data.x or 0
    decal.y = data.y or 0

    decal.scaleX = data.scaleX or 0
    decal.scaleY = data.scaleY or 0

    decal.rotation = data.rotation or 0

    return decal
end

function decalStruct.encode(decal)
    local res = {}

    res.__name = "decal"

    res.scaleX = decal.scaleX
    res.scaleY = decal.scaleY

    res.x = decal.x
    res.y = decal.y

    if decal.rotation ~= 0 then
        res.rotation = decal.rotation
    end

    res.texture = decalStruct.encodeDecalTexture(decal.texture)

    return res
end

return decalStruct