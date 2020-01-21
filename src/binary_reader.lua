local blobReader = require("moonblob.blob_reader")
local binfile = require("binfile")

local binaryReader = {}

binaryReader._MT = {}
binaryReader._MT.__index = {}

-- Add reading methods from binfile, fallback for not implemented functions
for name, func in pairs(binfile) do
    if name:match("^read") then
        binaryReader._MT.__index[name] = func
    end
end

function binaryReader._MT.__index:close()
    self._reader:reset("")
end

function binaryReader._MT.__index:read(n)
    return self._reader:raw(n or 1)
end

function binaryReader._MT.__index:readByte()
    return self._reader:u8()
end

function binaryReader._MT.__index:readBool()
    return self._reader:bool()
end

function binaryReader._MT.__index:readShort()
    return self._reader:u16()
end

function binaryReader._MT.__index:readSignedShort()
    return self._reader:s16()
end

function binaryReader._MT.__index:readLong()
    return self._reader:u32()
end

function binaryReader._MT.__index:readSignedLong()
    return self._reader:s32()
end

function binaryReader._MT.__index:readFloat()
    return self._reader:f32()
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

    reader._reader = blobReader(reader._content)

    return setmetatable(reader, binaryReader._MT)
end

setmetatable(binaryReader, {
    __call = function(self, ...)
        return binaryReader.create(...)
    end
})

return binaryReader