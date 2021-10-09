local binfile = require("utils.binfile")

local binaryReader = {}

binaryReader._MT = {}
binaryReader._MT.__index = {}

-- Add reading methods from binfile
for name, func in pairs(binfile) do
    if name:match("^read") then
        binaryReader._MT.__index[name] = func
    end
end

function binaryReader._MT.__index:close()
    -- Stub - Provided so it can be used in place of io.open file handle
end

function binaryReader._MT.__index:_updateBytes()
    if self._bytesLeft <= 0 then
        self._bytesLeft = self._bytesChunkSize
        self._bytesStart = self._ptr
        self._bytes = {string.byte(self._content, self._ptr, self._ptr + self._bytesChunkSize - 1)}
    end
end

-- Override readByte from binfile, this is faster
function binaryReader._MT.__index:readByte()
    self:_updateBytes()

    self._ptr = self._ptr + 1
    self._bytesLeft = self._bytesLeft - 1

    return self._bytes[self._ptr - self._bytesStart]
end

-- Override readBytes from binfile, this is faster
function binaryReader._MT.__index:readBytes(n)
    n = n or 1
    self._ptr = self._ptr + n
    self._bytesLeft = self._bytesLeft - n

    return self._content:byte(self._ptr - n, self._ptr - 1)
end

function binaryReader._MT.__index:read(n)
    n = n or 1
    self._ptr = self._ptr + n
    self._bytesLeft = self._bytesLeft - n

    return self._content:sub(self._ptr - n, self._ptr - 1)
end

function binaryReader.create(s)
    local reader = {
        _type = "binary_reader"
    }

    local typ = type(s)

    if typ == "userdata" then
        reader._content = s:read("*a")

        s:close()

    elseif typ == "string" then
        reader._content = s
    end

    reader._ptr = 1
    reader._bytes = nil
    reader._bytesStart = nil
    reader._bytesChunkSize = 1024
    reader._bytesLeft = 0

    return setmetatable(reader, binaryReader._MT)
end

setmetatable(binaryReader, {
    __call = function(self, ...)
        return binaryReader.create(...)
    end
})

return binaryReader