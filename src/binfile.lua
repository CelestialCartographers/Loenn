local binfile = {}

function binfile.twosCompliment(n, power)
    if n >= 2^(power - 1) then
        return n - 2^power

    else
        return n
    end
end

function binfile.readByte(fh)
    return string.byte(fh:read(1))
end

function binfile.writeByte(fh, n)
    fh:write(string.char(n))
end

function binfile.readShort(fh)
    return binfile.readByte(fh) + binfile.readByte(fh) * 256
end

function binfile.writeShort(fh, n)
    binfile.writeByte(fh, n % 256)
    binfile.writeByte(fh, math.floor(n / 256) % 256)
end

function binfile.readLong(fh)
    return binfile.readByte(fh) + binfile.readByte(fh) * 256 + binfile.readByte(fh) * 256^2 + binfile.readByte(fh) * 256^3
end

function binfile.writeLong(fh, n)
    binfile.writeByte(fh, n % 256)
    binfile.writeByte(fh, math.floor(n / 256) % 256)
    binfile.writeByte(fh, math.floor(n / 256^2) % 256)
    binfile.writeByte(fh, math.floor(n / 256^3) % 256)
end

function binfile.readBool(fh)
    return binfile.readByte(fh) ~= 0
end

function binfile.writeBool(fh, b)
    binfile.writeByte(fh, b and 1 or 0)
end

function binfile.readSignedShort(fh)
    return binfile.twosCompliment(binfile.readShort(fh), 16)
end

function binfile.writeSignedShort(fh, n)
    binfile.writeShort(fh, binfile.twosCompliment(n, 16))
end

function binfile.readSignedLong(fh)
    return binfile.twosCompliment(binfile.readLong(fh), 32)
end

function binfile.writeSignedLong(fh, n)
    binfile.writeLong(fh, binfile.twosCompliment(n, 32))
end

function binfile.readFloat(fh)
    local b4, b3, b2, b1 = string.byte(fh:read(4), 1, 4)

    local exponent = (b1 % 128) * 2 + math.floor(b2 / 128)

    if exponent == 0 then
        return 0.0
    end

    local sign = (b1 > 127) and -1 or 1
    local mantissa = ((b2 % 128) * 256 + b3) * 256 + b4
    mantissa = (math.ldexp(mantissa, -23) + 1) * sign

    return math.ldexp(mantissa, exponent - 127)
end

function binfile.writeFloat(fh, n)
    local val = n
    local sign = 0

    if val < 0 then
        sign = 1
        val = -val
    end

    local mantissa, exponent = math.frexp(val)

    if val == 0 then
        mantissa = 0
        exponent = 0

    else
        mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
        exponent = exponent + 126
    end

    binfile.writeByte(fh, math.floor(mantissa) % 256)
    val = math.floor(mantissa / 256)
    binfile.writeByte(fh, math.floor(val) % 256)
    val = math.floor(val / 256)

    binfile.writeByte(fh, math.floor(exponent * 128 + val) % 256)
    val = math.floor((exponent * 128 + val) / 256)
    binfile.writeByte(fh, math.floor(sign * 128 + val) % 256)
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

function binfile.getVariableLength(fh, length)
    local res = $()

    while length > 127 do
        res += length % 128 + 128
        length = math.floor(length / 128)
    end

    res += length

    return res
end

function binfile.writeVariableLength(fh, length)
    binfile.writeByteArray(fh, binfile.getVariableLength(fh, length)())
end

function binfile.readString(fh)
    local length = binfile.readVariableLength(fh)
    local res = fh:read(length)

    return res
end

function binfile.writeString(fh, value)
    binfile.writeVariableLength(fh, #value)
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

function binfile.encodeRunLength(value)
    local res = $()
    local value = $(value)

    local count = 1
    local current = value[1]

    for index, char <- value do
        if index > 1 then
            if char ~= current or count == 255 then
                res += count
                res += string.byte(current)

                count = 1
                current = char

            else
                count += 1
            end
        end
    end

    res += count
    res += string.byte(current)

    return res()
end

function binfile.writeRunLengthEncoded(fh, value)
    local payload = binfile.encodeRunLength(value)

    binfile.writeShort(fh, #payload)
    binfile.writeByteArray(fh, payload)
end

function binfile.writeByteArray(fh, t)
    fh:write(string.char(unpack(t)))
end

return binfile