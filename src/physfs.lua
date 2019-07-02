-- TODO - More methods from https://godoc.org/github.com/DeedleFake/Go-PhysicsFS/physfs ?

local physfs = {}

local ffi = require('ffi')
local l = ffi.os == 'Windows' and ffi.load('love') or ffi.C

ffi.cdef [[
    int PHYSFS_mount(const char *newDir, const char *mountPoint, int appendToPath);
    int PHYSFS_mkdir(const char *dir);
    bool PHYSFS_isDirectory(const char *dir);
    char* PHYSFS_getDirSeparator();
    int PHYSFS_init();
]]

l.PHYSFS_init()

physfs.mount = l.PHYSFS_mount
physfs.mkdir = l.PHYSFS_mkdir
physfs.isDirectory = l.PHYSFS_isDirectory

function physfs.getDirSeparator()
    return ffi.string(l.PHYSFS_getDirSeparator())
end

return physfs