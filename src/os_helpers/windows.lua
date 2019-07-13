local ffi = require("ffi")

ffi.cdef([[
    int GetCurrentProcessId();
]])

local helper = {}

function helper.getProcessId()
    return ffi.C.GetCurrentProcessId()
end

return helper