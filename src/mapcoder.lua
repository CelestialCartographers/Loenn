local serialization = require("serialization")

local binfile = require("binfile")

local function look(fh, lookup)
    return lookup[binfile.readShort(fh) + 1]
end

decodeFunctions = {
    binfile.readBool,
    binfile.readByte,
    binfile.readSignedShort,
    binfile.readSignedLong,
    binfile.readFloat
}

local function decodeValue(fh, lookup, typ)
    if typ >= 0 and typ <= 4 then
        return decodeFunctions[typ + 1](fh)

    elseif typ == 5 then
        return look(fh, lookup)

    elseif typ == 6 then
        return binfile.readString(fh)

    elseif typ == 7 then
        return binfile.readRunLengthEncoded(fh)
    end
end

local function decodeElement(fh, lookup, parent)
    name = look(fh, lookup)
    element = {__children, __name=name}
    attributeCount = binfile.readByte(fh)

    for i = 1, attributeCount do
        key = look(fh, lookup)
        typ = binfile.readByte(fh)

        value = decodeValue(fh, lookup, typ)

        if key then
            element[key] = value
        end
    end

    parent.__children = parent.__children or $()
    parent.__children += element

    elementCount = binfile.readShort(fh)

    for i = 1, elementCount do
        decodeElement(fh, lookup, element)
    end
end

local function decodeFile(path, header)
    local header = header or "CELESTE MAP"
    local fh = io.open(path, "rb")
    local res = {}

    if binfile.readString(fh) ~= header then
        print("Invalid Celeste map file")

        return false
    end

    local package = binfile.readString(fh)

    local lookupLength = binfile.readShort(fh)
    local lookup = $()

    for i = 1, lookupLength do
        lookup += binfile.readString(fh)
    end

    res._package = package
    decodeElement(fh, lookup, res)

    fh:close()

    return true
end

local function encodeFile(path, data)

end

return {
    decodeFile = decodeFile,
    encodeFile = encodeFile
}