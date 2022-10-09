local binfile = require("utils.binfile")
local binaryReader = require("utils.binary_reader")
local binaryWriter = require("utils.binary_writer")
local utf8 = require("utf8")

local mapcoder = {}

function mapcoder.look(reader, lookup)
    return lookup[reader:readShort() + 1]
end

local decodeFunctions = {
    "readBool",
    "readByte",
    "readSignedShort",
    "readSignedLong",
    "readFloat"
}

local typeHeaders = {
    bool = 0,
    byte = 1,
    signedShort = 2,
    signedLong = 3,
    float32 = 4,
    stringLookup = 5,
    string = 6,
    runLengthEncoded = 7
}

local function decodeValue(reader, lookup, typ)
    if typ >= 0 and typ <= 4 then
        return reader[decodeFunctions[typ + 1]](reader)

    elseif typ == 5 then
        return mapcoder.look(reader, lookup)

    elseif typ == 6 then
        return reader:readString()

    elseif typ == 7 then
        return reader:readRunLengthEncoded()
    end
end

local function decodeElement(reader, lookup)
    coroutine.yield()

    local name = mapcoder.look(reader, lookup)
    local element = {__name=name}
    local attributeCount = reader:readByte()

    for i = 1, attributeCount do
        local key = mapcoder.look(reader, lookup)
        local typ = reader:readByte()

        local value = decodeValue(reader, lookup, typ)

        if key then
            element[key] = value
        end
    end

    local elementCount = reader:readShort()

    if elementCount > 0 then
        element.__children = {}

        for i = 1, elementCount do
            table.insert(element.__children, decodeElement(reader, lookup))
        end
    end

    return element
end

function mapcoder.decodeFile(path, header)
    header = header or "CELESTE MAP"

    local writer = io.open(path, "rb")
    local res = {}

    if not writer then
        return false, "File not found"
    end

    local reader = binaryReader(writer)

    if #header > 0 and reader:readString() ~= header then
        return false, "Invalid Celeste map file"
    end

    local package = reader:readString()

    local lookupLength = reader:readShort()
    local lookup = {}

    for i = 1, lookupLength do
        lookup[i] = reader:readString()
    end

    res = decodeElement(reader, lookup)
    res._package = package

    coroutine.yield("update", res)

    return res
end

local function countStrings(data, seen)
    seen = seen or {}

    local name = data.__name or ""
    local children = data.__children

    seen[name] = (seen[name] or 0) + 1

    for k, v in pairs(data) do
        if type(k) == "string" and k ~= "__name" and k ~= "__children" then
            seen[k] = (seen[k] or 0) + 1
        end

        if type(v) == "string" and k ~= "innerText" then
            seen[v] = (seen[v] or 0) + 1
        end
    end

    if children then
        for i, child in ipairs(children) do
            countStrings(child, seen)
        end
    end

    return seen
end

local integerBits = {
    {typeHeaders.byte, 0, 255, "writeByte"},
    {typeHeaders.signedShort, -32768, 32767, "writeSignedShort"},
    {typeHeaders.signedLong, -2147483648, 2147483647, "writeSignedLong"},
}

function mapcoder.encodeNumber(writer, n, lookup)
    -- Needs special check for infinity and NaN
    local float = n ~= math.floor(n) or math.abs(n) == math.huge or n ~= n

    if float then
        writer:writeByte(typeHeaders.float32)
        writer:writeFloat(n)

    else
        for i, d in ipairs(integerBits) do
            local header, min, max, func = d[1], d[2], d[3], d[4]

            if n >= min and n <= max then
                writer:writeByte(header)
                writer[func](writer, n)

                return
            end
        end

        -- Number was outside of integer ranges, save it as a float instead
        -- This will lose precisision, but we can't tell if the original number was a float or integer
        writer:writeByte(typeHeaders.float32)
        writer:writeFloat(n)
    end
end

function mapcoder.encodeBoolean(writer, b, lookup)
    writer:writeByte(typeHeaders.bool)
    writer:writeBool(b)
end

local function findInLookup(lookup, s)
    return lookup[s]
end

function mapcoder.encodeString(writer, s, lookup)
    local index = findInLookup(lookup, s)

    if index then
        writer:writeByte(5)
        writer:writeSignedShort(index - 1)

    else
        local encodedString = binfile.encodeRunLength(s)
        local encodedLength = #encodedString
        local utf8Length = utf8.len(s)
        local length = #s

        -- Only allow run length encoding if the string contains only 1 byte characters
        -- Celeste does not read it as expected otherwise, this is mainly a tile issue
        -- Run length encoding has a hardcoded max length, make sure we don't exceed the limit
        if length == utf8Length and encodedLength < utf8Length and encodedLength < 2^15 then
            writer:writeByte(7)
            writer:writeSignedShort(encodedLength)
            writer:write(encodedString)

        else
            writer:writeByte(6)
            writer:writeString(s)
        end
    end
end

function mapcoder.encodeTable(writer, data, lookup)
    coroutine.yield()

    local index = findInLookup(lookup, data.__name)

    local attributes = {}
    local attributeCount = 0

    local children = data.__children or {}

    for attr, value in pairs(data) do
        if attr ~= "__children" and attr ~= "__name" then
            table.insert(attributes, attr)
            table.insert(attributes, value)

            attributeCount += 1
        end
    end

    writer:writeShort(index - 1)
    writer:writeByte(attributeCount)

    for i = 1, #attributes, 2 do
        local attr = attributes[i]
        local value = attributes[i + 1]
        local attrIndex = findInLookup(lookup, attr)

        writer:writeShort(attrIndex - 1)
        mapcoder.encodeValue(writer, value, lookup)
    end

    writer:writeShort(#children)

    for i, child in ipairs(children) do
        mapcoder.encodeTable(writer, child, lookup)
    end
end

local encodingFunctions = {
    number = mapcoder.encodeNumber,
    boolean = mapcoder.encodeBoolean,
    string = mapcoder.encodeString,
    table = mapcoder.encodeTable
}

function mapcoder.encodeValue(writer, value, lookup)
    encodingFunctions[type(value)](writer, value, lookup)
end

function mapcoder.encodeFile(path, data, header)
    header = header or "CELESTE MAP"

    local writer = binaryWriter()

    local stringsSeen = countStrings(data)
    local lookupStrings = {}
    local lookupTable = {}

    for s, c in pairs(stringsSeen) do
        table.insert(lookupStrings, s)
    end

    writer:writeString(header)
    writer:writeString(data._package or "")
    writer:writeShort(#lookupStrings)

    -- Write the lookup table to string
    -- But also generate a faster lookup table for the encoding functions
    for i, lookup in ipairs(lookupStrings) do
        writer:writeString(lookup)

        lookupTable[lookup] = i
    end

    mapcoder.encodeTable(writer, data, lookupTable)

    local content = writer:getString()
    local fh = io.open(path, "wb")

    if fh then
        fh:write(content)
        fh:close()
        writer:close()
    end

    coroutine.yield()
end

return mapcoder