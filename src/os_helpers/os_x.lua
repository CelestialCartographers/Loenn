local ffi = require("ffi")

ffi.cdef([[
    int getpid();
]])

local helper = {}

function helper.getProcessId()
    return ffi.C.getpid()
end

return helper