-- TODO - See if possible to also add https://godoc.org/github.com/DeedleFake/Go-PhysicsFS/physfs#Mkdir `createDirectoryUnsandboxed`

local ffi = require('ffi')
local l = ffi.os == 'Windows' and ffi.load('love') or ffi.C

ffi.cdef [[
    int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);
]]

love.filesystem.mountUnsandboxed = l.PHYSFS_mount