local decal_struct = {}

-- Replace \ with /, remove .png and prefix with `decals/`
function decal_struct.get_decal_texture(texture)
    return "decals/" .. texture:gsub("\\", "/"):sub(1, #texture - 4)
end

function decal_struct.decode(data)
    local decal = {
        _type = "decal",
        _raw = data
    }

    decal.texture = decal_struct.get_decal_texture(data.texture or "")

    decal.x = data.x or 0
    decal.y = data.y or 0

    decal.scaleX = data.scaleX or 0
    decal.scaleY = data.scaleY or 0

    return decal
end

function decal_struct.encode(decal)

end

return decal_struct