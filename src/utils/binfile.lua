-- Pure Lua binary file implementation

local mathFloor = math.floor
local mathLdexp = math.ldexp
local mathHuge = math.huge

local stringByte = string.byte
local stringChar = string.char
local stringSub = string.sub

local binfile = {}

function binfile.twosCompliment(n, power)
    if n >= 2^(power - 1) then
        return n - 2^power

    else
        return n
    end
end

function binfile.readByte(fh)
    return stringByte(fh:read(1))
end

function binfile.writeByte(fh, n)
    fh:write(stringChar(n))
end

function binfile.readBytes(fh, n)
    return stringByte(fh:read(n), 1, n)
end

function binfile.writeBytes(fh, ...)
    fh:write(stringChar(...))
end

function binfile.readShort(fh)
    local b1, b2 = binfile.readBytes(fh, 2)

    return b1 + b2 * 256
end

function binfile.writeShort(fh, n)
    binfile.writeBytes(fh, n % 256, mathFloor(n / 256) % 256)
end

function binfile.readLong(fh)
    local b1, b2, b3, b4 = binfile.readBytes(fh, 4)

    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

function binfile.writeLong(fh, n)
    binfile.writeBytes(fh, n % 256, mathFloor(n / 256) % 256, mathFloor(n / 65536) % 256, mathFloor(n / 16777216) % 256)
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
    local b4, b3, b2, b1 = binfile.readBytes(fh, 4)
    local exponent = (b1 % 128) * 2 + mathFloor(b2 / 128)

    if exponent == 0 then
        return 0.0
    end

    local sign = (b1 > 127) and -1 or 1
    local mantissa = ((b2 % 128) * 256 + b3) * 256 + b4

    -- Infinity/NaN check
    -- Eight 1s in exponent is infinity/NaN
    if exponent == 255 then
        if mantissa == 0 then
            return mathHuge * sign

        else
            return 0 / 0
        end
    end

    mantissa = (mathLdexp(mantissa, -23) + 1) * sign

    return mathLdexp(mantissa, exponent - 127)
end

function binfile.writeFloat(fh, n)
    local b1, b2, b3, b4

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

    elseif val == mathHuge then
        -- Exponent is all 1s and mantissa is all 0s on infinity
        mantissa = 0
        exponent = 255 -- Eight 1s

    elseif val ~= val then
        -- NaN is not equal NaN
        -- Exponent is all 1s and mantissa is not 0 on NaN
        mantissa = 1
        exponent = 255 -- Eight 1s

    else
        mantissa = (mantissa * 2 - 1) * mathLdexp(0.5, 24)
        exponent = exponent + 126
    end

    b1 = mathFloor(mantissa) % 256
    val = mathFloor(mantissa / 256)
    b2 = mathFloor(val) % 256
    val = mathFloor(val / 256)

    b3 = mathFloor(exponent * 128 + val) % 256
    val = mathFloor((exponent * 128 + val) / 256)
    b4 = mathFloor(sign * 128 + val) % 256

    binfile.writeBytes(fh, b1, b2, b3, b4)
end

function binfile.readVariableLength(fh)
    local res = 0
    local multiplier = 1

    while true do
        local byte = binfile.readByte(fh)

        if byte < 128 then
            return res + byte * multiplier

        else
            res = res + (byte - 128) * multiplier
        end

        multiplier = multiplier * 128
    end
end

function binfile.getVariableLength(fh, length)
    local res = {}

    while length > 127 do
        table.insert(res, length % 128 + 128)

        length = mathFloor(length / 128)
    end

    table.insert(res, length)

    return res
end

function binfile.writeVariableLength(fh, length)
    while length > 127 do
        binfile.writeByte(fh, length % 128 + 128)

        length = mathFloor(length / 128)
    end

    binfile.writeByte(fh, length)
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
    local res = {}

    for i = 1, bytes, 2 do
        local times, char = binfile.readBytes(fh, 2)

        table.insert(res, stringChar(char):rep(times))
    end

    return table.concat(res)
end

-- TODO - This is slow, consider doing it with FFI
function binfile.encodeRunLength(str)
    local res = {}

    local count = 1
    local current = stringSub(str, 1, 1)

    for index = 1, #str do
        local char = stringSub(str, index, index)

        if index > 1 then
            if char ~= current or count == 255 then
                table.insert(res, stringChar(count))
                table.insert(res, current)

                count = 1
                current = char

            else
                count = count + 1
            end
        end
    end

    table.insert(res, stringChar(count))
    table.insert(res, current)

    return table.concat(res)
end

function binfile.writeRunLengthEncoded(fh, value)
    local payload = binfile.encodeRunLength(value)

    binfile.writeShort(fh, #payload)
    binfile.write(fh, payload)
end

function binfile.writeByteArray(fh, t)
    fh:write(stringChar(unpack(t)))
end

return binfile