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
    if #self._unwritten > 0 then
        for _, part in ipairs(self._unwritten) do
            self._fh:write(part)
        end

        self._unwritten = {}
    end
end

function binaryWriter._MT.__index:close()
    self:flush()

    if self._fh then
        self._fh:close()
    end
end

function binaryWriter._MT.__index:write(s)
    table.insert(self._unwritten, s)
    self._unwrittenBytes = self._unwrittenBytes + #s

    if self._unwrittenBytes > self._unwrittenMaxSize then
        self:flush()
    end
end

function binaryWriter.create(fh)
    local writer = {
        _type = "binary_writer"
    }

    if not fh then
        return
    end

    writer._fh = fh
    writer._unwrittenMaxSize = 4096
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