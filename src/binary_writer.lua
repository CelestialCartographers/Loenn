local binfile = require("binfile")

local binaryWriter = {}

binaryWriter._MT = {}
binaryWriter._MT.__index = {}

-- Add reading methods from binfile
for name, func in pairs(binfile) do
    if name:match("^write") then
        binaryWriter._MT.__index[name] = func
    end
end

function binaryWriter._MT.__index:flush()
    if self._fh and #self._unwritten > 0 then
        self._fh:write(table.concat(self._unwritten))

        self._unwritten = {}
    end
end

function binaryWriter._MT.__index:close()
    self:flush()

    if self._fh then
        self._fh:close()
    end
end

function binaryWriter._MT.__index:getString()
    return table.concat(self._unwritten)
end

function binaryWriter._MT.__index:write(s)
    table.insert(self._unwritten, s)
    self._unwrittenBytes = self._unwrittenBytes + #s

    if self._fh and self._unwrittenBytes > self._unwrittenMaxSize then
        self:flush()
    end
end

function binaryWriter.create(fh, unwrittenMaxSize)
    local writer = {
        _type = "binary_writer"
    }

    writer._fh = fh
    writer._unwrittenMaxSize = unwrittenMaxSize or 4096
    writer._unwrittenBytes = 0
    writer._unwritten = {}

    return setmetatable(writer, binaryWriter._MT)
end

setmetatable(binaryWriter, {
    __call = function(self, ...)
        return binaryWriter.create(...)
    end
})

return binaryWriter