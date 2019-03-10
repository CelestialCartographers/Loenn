local decalStruct = {}

-- Replace \ with /, remove .png and prefix with `decals/`
function decalStruct.getDecalTexture(texture)
    return "decals/" .. texture:gsub("\\", "/"):sub(1, #texture - 4)
end

function decalStruct.decode(data)
    local decal = {
        _type = "decal",
        _raw = data
    }

    decal.texture = decalStruct.getDecalTexture(data.texture or "")

    decal.x = data.x or 0
    decal.y = data.y or 0

    decal.scaleX = data.scaleX or 0
    decal.scaleY = data.scaleY or 0

    return decal
end

function decalStruct.encode(decal)

end

return decalStruct