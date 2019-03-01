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
    local res = $()

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
    local res = $()
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

return {
    readBool = readBool,
    readByte = readByte,
    readShort = readShort,
    readSignedShort = readSignedShort,
    readLong = readLong,
    readSignedLong = readSignedLong,
    readFloat = readFloat,

    readVariableLength = readVariableLength,
    readRunLengthEncoded = readRunLengthEncoded,
    readString = readString,

    writeVariableLength = writeVariableLength,
    writeRunLengthEncoded = writeRunLengthEncoded,
    writeString = writeString   
}