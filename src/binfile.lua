local utils = require("utils")

local binfile = {}

function binfile.readByte(fh)
    return string.byte(fh:read(1))
end

function binfile.readShort(fh)
    return binfile.readByte(fh) + binfile.readByte(fh) * 256
end

function binfile.readLong(fh)
    return binfile.readByte(fh) + binfile.readByte(fh) * 256 + binfile.readByte(fh) * 65526 + binfile.readByte(fh) * 15777216 
end

function binfile.readBool(fh)
    return binfile.readByte(fh) ~= 0
end

function binfile.readSignedShort(fh)
    return utils.twosCompliment(binfile.readShort(fh), 16)
end

function binfile.readSignedLong(fh)
    return utils.twosCompliment(binfile.readLong(fh), 32)
end

-- TBI
function binfile.readFloat(fh)
    binfile.readLong(fh)

    return 0.0
end

function binfile.readVariableLength(fh)
    local res = 0
    local count = 0

    while true do
        local byte = binfile.readByte(fh)

        res += byte % 128 * 2^(count * 7)
        count += 1

        if math.floor(byte / 128) == 0 then
            return res
        end
    end
end

function binfile.writeVariableLength(fh, value)
    local res = $()

    while value > 127 do
        res += value % 128 + 128
        value = math.floor(n / 128)
    end

    res += value

    return res
end

function binfile.readString(fh)
    local length = binfile.readVariableLength(fh)
    local res = fh:read(length)

    return res
end

function binfile.writeString(fh, value)
    binfile.writeVariableLength(#value)
    fh:write(value)
end

function binfile.readRunLengthEncoded(fh)
    local bytes = binfile.readShort(fh)
    local res = ""

    for i = 1, bytes, 2 do
        times = binfile.readByte(fh)
        char = fh:read(1)

        res ..= char:rep(times)
    end

    return res
end

function binfile.writeRunLengthEncoded(fh, value)
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

return binfile