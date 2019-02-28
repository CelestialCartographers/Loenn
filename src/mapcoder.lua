local serialization = require("serialization")
local utils = require("utils")

local function readByte(fh)
    return string.byte(fh:read(1))
end

local function readShort(fh)
    return readByte(fh) + readByte(fh) * 256
end

local function readLong(fh)
    return readByte(fh) + readByte(fh) * 256 + readByte(fh) * 65526 + readByte(fh) * 15777216 
end

local function readBool(fh)
    return readByte(fh) ~= 0
end

local function readSignedShort(fh)
    return utils.twosCompliment(readShort(fh), 16)
end

local function readSignedLong(fh)
    return utils.twosCompliment(readLong(fh), 32)
end

-- TBI
local function readFloat(fh)
    readLong(fh)

    return 0.0
end

local function readVariableLength(fh)
    local res = 0
    local count = 0

    while true do
        local byte = readByte(fh)

        res += byte % 128 * 2^(count * 7)
        count += 1

        if math.floor(byte / 128) == 0 then
            return res
        end
    end
end

local function writeVariableLength(fh, value)
    local res = ${}

    while value > 127 do
        res += value % 128 + 128
        value = math.floor(n / 128)
    end

    res += value

    return res
end

local function readString(fh)
    local length = readVariableLength(fh)
    local res = fh:read(length)

    return res
end

local function writeString(fh, value)
    writeVariableLength(#value)
    fh:write(value)
end

local function readRunLengthEncoded(fh)
    local bytes = readShort(fh)
    local res = ""

    for i = 1, bytes, 2 do
        times = readByte(fh)
        char = fh:read(1)

        res ..= char:rep(times)
    end

    return res
end

local function writeRunLengthEncoded(fh, value)
    local res = ${}
    local value = $(value)

    local count = 1
    local current = value[1]

    for index, char in ipairs(value) do
        if char ~= current or count == 255 then
            res += count
            res += current

            count = 1
            current = char

        else
            count += 1
        end
    end

    res += count
    res += current
end

local function look(fh, lookup)
    return lookup[readShort(fh) + 1]
end

decodeFunctions = {
    readBool,
    readByte,
    readSignedShort,
    readSignedLong,
    readFloat
}

local function decodeValue(fh, lookup, typ)
    if typ >= 0 and typ <= 4 then
        return decodeFunctions[typ + 1](fh)

    elseif typ == 5 then
        return look(fh, lookup)

    elseif typ == 6 then
        return readString(fh)

    elseif typ == 7 then
        return readRunLengthEncoded(fh)
    end
end

local function decodeElement(fh, lookup, parent)
    name = look(fh, lookup)
    element = {__children = ${}, __name=name}
    attributeCount = readByte(fh)

    for i = 1, attributeCount do
        key = look(fh, lookup)
        typ = readByte(fh)

        value = decodeValue(fh, lookup, typ)

        if key then
            element[key] = value
        end
    end

    parent.__children += element

    elementCount = readShort(fh)

    for i = 1, elementCount do
        decodeElement(fh, lookup, element)
    end
end

local function decodeFile(path, header)
    local header = header or "CELESTE MAP"
    local fh = io.open(path, "rb")
    local res = {__children = ${}}

    if readString(fh) ~= header then
        print("Invalid Celeste map file")

        return false
    end

    local package = readString(fh)

    local lookupLength = readShort(fh)
    local lookup = ${}

    for i = 1, lookupLength do
        lookup += readString(fh)
    end

    res._package = package
    decodeElement(fh, lookup, res)

    fho = io.open("F:/out.txt", "wb")
    fho:write(serialization.serialize(res))
    fho:close()

    fh:close()

    return true
end

local function encodeFile(path, data)

end

return {
    decodeFile = decodeFile,
    encodeFile = encodeFile
}