local blobWriter = require("moonblob.blob_writer")
local binfile = require("binfile")

local binaryWriter = {}

binaryWriter._MT = {}
binaryWriter._MT.__index = {}

-- Add writing methods from binfile, fallback for not implemented functions
for name, func in pairs(binfile) do
    if name:match("^write") then
        binaryWriter._MT.__index[name] = func
    end
end

function binaryWriter._MT.__index:flush()
    if self._fh then
        self._fh:write(self._writer:tostring())
    end

    self._writer:clear()
end

function binaryWriter._MT.__index:close()
    if self._fh then
        self._fh:write(self._writer:tostring())
        self._fh:close()
    end

    self._writer:clear(0)
end

function binaryWriter._MT.__index:getString()
    return self._writer:tostring()
end

function binaryWriter._MT.__index:write(s)
    self._writer:raw(s)
end

function binaryWriter._MT.__index:writeByte(n)
    self._writer:u8(n)
end

function binaryWriter._MT.__index:writeBytes(...)
    self._writer:raw(string.char(...))
end

function binaryWriter._MT.__index:writeByteArray(t)
    for i = 1, #t do
        self._writer:u8(t[i])
    end
end

function binaryWriter._MT.__index:writeBool(n)
    self._writer:bool(n)
end

function binaryWriter._MT.__index:writeShort(n)
    self._writer:u16(n)
end

function binaryWriter._MT.__index:writeSignedShort(n)
    self._writer:s16(n)
end

function binaryWriter._MT.__index:writeLong(n)
    self._writer:u32(n)
end

function binaryWriter._MT.__index:writeSignedLong(n)
    self._writer:s32(n)
end

function binaryWriter._MT.__index:writeFloat(n)
    self._writer:f32(n)
end

function binaryWriter.create(fh)
    local writer = {
        _type = "binary_writer"
    }

    writer._fh = fh
    writer._writer = blobWriter()

    return setmetatable(writer, binaryWriter._MT)
end

setmetatable(binaryWriter, {
    __call = function(self, ...)
        return binaryWriter.create(...)
    end
})

return binaryWriter