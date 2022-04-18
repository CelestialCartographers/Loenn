local ffi = require("ffi")

-- ffi to love.system names
local ffiOSLookup = {
    Windows = "Windows",
    Linux = "Linux",
    OSX = "OS X"
}

local osUtils = {}

function osUtils.getOS()
    if love.system then
        return love.system.getOS()
    end

    -- Fallback to ffi.os, some names differ but it is good enough
    return ffiOSLookup[ffi.os]
end

return osUtils