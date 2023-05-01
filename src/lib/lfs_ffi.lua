--[===[
    MIT License

    Copyright (c) 2016 罗泽轩

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]===]

local bit = require "bit"
local ffi = require "ffi"


local band = bit.band
local rshift = bit.rshift
local lib = ffi.C
local ffi_str = ffi.string
local concat = table.concat
local has_table_new, new_tab = pcall(require, "table.new")
if not has_table_new or type(new_tab) ~= "function" then
    new_tab = function () return {} end
end


local _M = {
    _VERSION = "0.1",
}

-- common utils/constants
local IS_64_BIT = ffi.abi('64bit')
local ERANGE = 'Result too large'

if not pcall(ffi.typeof, "ssize_t") then
    -- LuaJIT 2.0 doesn't have ssize_t as a builtin type, let's define it
    ffi.cdef("typedef intptr_t ssize_t")
end

ffi.cdef([[
    char* strerror(int errnum);
]])

local function errno()
    return ffi_str(lib.strerror(ffi.errno()))
end

local OS = ffi.os
-- sys/syslimits.h
local MAXPATH
local MAXPATH_UNC = 32760
local HAVE_WFINDFIRST = true
local wchar_t
local win_utf8_to_unicode
local win_unicode_to_utf8
if OS == 'Windows' then
    MAXPATH = 260
    ffi.cdef([[
        typedef int mbstate_t;
        /*
        In VC2015, M$ change the definition of mbstate_t to this and breaks the ABI.
        */
        typedef struct _Mbstatet
        { // state of a multibyte translation
            unsigned long _Wchar;
            unsigned short _Byte, _State;
        } _Mbstatet;
        typedef _Mbstatet mbstate_t;

        size_t mbrtowc(wchar_t* pwc,
            const char* s,
            size_t n,
            mbstate_t* ps);
    ]])

    function wchar_t(s)
        local mbstate = ffi.new('mbstate_t[1]')
        local wcs = ffi.new('wchar_t[?]', #s + 1)
        local i = 0
        local offset = 0
        local len = #s
        while true do
            local processed = lib.mbrtowc(
                wcs + i, ffi.cast('const char *', s) + offset, len, mbstate)
            if processed <= 0 then break end
            i = i + 1
            offset = offset + processed
            len = len - processed
        end
        return wcs
    end

elseif OS == 'Linux' then
    MAXPATH = 4096
else
    MAXPATH = 1024
end

-- misc
if OS == "Windows" then
    local utime_def
    if IS_64_BIT then
        utime_def = [[
            typedef __int64 time_t;
            struct __utimebuf64 {
                time_t actime;
                time_t modtime;
            };
            typedef struct __utimebuf64 utimebuf;
            int _utime64(unsigned char *file, utimebuf *times);
        ]]
    else
        utime_def = [[
            typedef __int32 time_t;
            struct __utimebuf32 {
                time_t actime;
                time_t modtime;
            };
            typedef struct __utimebuf32 utimebuf;
            int _utime632(unsigned char *file, utimebuf *times);
        ]]
    end

    ffi.cdef([[
        char *_getcwd(char *buf, size_t size);
        wchar_t *_wgetcwd(wchar_t *buf, size_t size);
        int _chdir(const char *path);
        int _wchdir(const wchar_t *path);
        int _rmdir(const char *pathname);
        int _wrmdir(const wchar_t *pathname);
        int _mkdir(const char *pathname);
        int _wmkdir(const wchar_t *pathname);
        ]] .. utime_def .. [[
        typedef wchar_t* LPTSTR;
        typedef unsigned char BOOLEAN;
        typedef unsigned long DWORD;
        BOOLEAN CreateSymbolicLinkW(
            LPTSTR lpSymlinkFileName,
            LPTSTR lpTargetFileName,
            DWORD dwFlags
        );

        int _fileno(struct FILE *stream);
        int _setmode(int fd, int mode);
    ]])
    
    ffi.cdef([[

    size_t wcslen(const wchar_t *str);
    wchar_t *wcsncpy(wchar_t *strDest, const wchar_t *strSource, size_t count);
    
    int WideCharToMultiByte(
        unsigned int     CodePage,
        DWORD    dwFlags,
        const wchar_t*  lpWideCharStr,
        int      cchWideChar,
        char*    lpMultiByteStr,
        int      cbMultiByte,
        const char*   lpDefaultChar,
        int*   lpUsedDefaultChar);
    
    int MultiByteToWideChar(
        unsigned int     CodePage,
        DWORD    dwFlags,
        const char*   lpMultiByteStr,
        int      cbMultiByte,
        wchar_t*   lpWideCharStr,
        int      cchWideChar);
    
    ]])
    ffi.cdef[[
        
        uint32_t GetLastError();
        uint32_t FormatMessageA(
            uint32_t dwFlags,
            const void* lpSource,
            uint32_t dwMessageId,
            uint32_t dwLanguageId,
            char* lpBuffer,
            uint32_t nSize,
            va_list *Arguments
        );
    ]]
    -- Some helper functions
    local function error_win(lvl)
        local errcode = ffi.C.GetLastError()
        local str = ffi.new("char[?]",1024)
        local FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;
        local FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
        local numout = ffi.C.FormatMessageA(bit.bor(FORMAT_MESSAGE_FROM_SYSTEM,
            FORMAT_MESSAGE_IGNORE_INSERTS), nil, errcode, 0, str, 1023, nil)
        if numout == 0 then
            error("Windows Error: (Error calling FormatMessage)", lvl)
        else
            error("Windows Error: "..ffi.string(str, numout), lvl)
        end
    end
    local CP_UTF8 = 65001
    local WC_ERR_INVALID_CHARS = 0x00000080
    local MB_ERR_INVALID_CHARS  = 0x00000008
    function win_utf8_to_unicode(szUtf8)
        local dwFlags = _M.unicode_errors and MB_ERR_INVALID_CHARS or 0
        local nLenWchar = lib.MultiByteToWideChar(CP_UTF8, dwFlags, szUtf8, -1, nil, 0 );
        if nLenWchar ==0 then error_win(2) end
        local szUnicode = ffi.new("wchar_t[?]",nLenWchar)
        nLenWchar = lib.MultiByteToWideChar(CP_UTF8, dwFlags, szUtf8, -1, szUnicode, nLenWchar);
        if nLenWchar ==0 then error_win(2) end
        return szUnicode, nLenWchar
    end
    _M.win_utf8_to_unicode = win_utf8_to_unicode
    function win_unicode_to_utf8( szUnicode)
        local dwFlags = _M.unicode_errors and WC_ERR_INVALID_CHARS or 0
        local nLen = lib.WideCharToMultiByte(CP_UTF8, dwFlags, szUnicode, -1, nil, 0, nil, nil);
        if nLen ==0 then error_win(2) end
        local str = ffi.new("char[?]",nLen)
        nLen = lib.WideCharToMultiByte(CP_UTF8, dwFlags, szUnicode, -1, str, nLen, nil, nil);
        if nLen ==0 then error_win(2) end
        return str
    end
    _M.win_unicode_to_utf8 = win_unicode_to_utf8
    local CP_ACP = 0
    function _M.win_utf8_to_acp(utf)
        local szUnicode = win_utf8_to_unicode(utf)
        local dwFlags = _M.unicode_errors and WC_ERR_INVALID_CHARS or 0
        local nLen = lib.WideCharToMultiByte(CP_ACP, dwFlags, szUnicode, -1, nil, 0, nil, nil);
        if nLen ==0 then error_win(2) end
        local str = ffi.new("char[?]",nLen)
        nLen = lib.WideCharToMultiByte(CP_ACP, dwFlags, szUnicode, -1, str, nLen, nil, nil);
        if nLen ==0 then error_win(2) end
        return ffi_str(str)
    end
    function _M.chdir(path)
        if _M.unicode then
            local uncstr = win_utf8_to_unicode(path)
            if lib._wchdir(uncstr) == 0 then return true end
        else
            if type(path) ~= 'string' then
                error('path should be a string')
            end
            if lib._chdir(path) == 0 then
                return true
            end
        end
        return nil, errno()
    end

    function _M.currentdir()
        if _M.unicode then
            local buf = ffi.new("wchar_t[?]",MAXPATH_UNC)
            if lib._wgetcwd(buf, MAXPATH_UNC) ~= nil then
                local buf_utf = win_unicode_to_utf8(buf)
                return ffi_str(buf_utf)
            end
            error("error in currentdir")
        else
        local size = MAXPATH
        while true do
            local buf = ffi.new("char[?]", size)
            if lib._getcwd(buf, size) ~= nil then
                return ffi_str(buf)
            end
            local err = errno()
            if err ~= ERANGE then
                return nil, err
            end
            size = size * 2
        end
        end
    end

    function _M.mkdir(path)
        if _M.unicode then
            local unc_str = win_utf8_to_unicode(path)
            if lib._wmkdir(unc_str) == 0 then
                return true
            end
        else
            if type(path) ~= 'string' then
                error('path should be a string')
            end
            if lib._mkdir(path) == 0 then
                return true
            end
        end
        return nil, errno()
    end

    function _M.rmdir(path)
        if _M.unicode then
            local unc_str = win_utf8_to_unicode(path)
            if lib._wrmdir(unc_str) == 0 then
                return true
            end
        else
            if type(path) ~= 'string' then
                error('path should be a string')
            end
            if lib._rmdir(path) == 0 then
                return true
            end
        end
        return nil, errno()
    end

    function _M.touch(path, actime, modtime)
        local buf

        if type(actime) == "number" then
            modtime = modtime or actime
            buf = ffi.new("utimebuf")
            buf.actime  = actime
            buf.modtime = modtime
        end

        local p = ffi.new("unsigned char[?]", #path + 1)
        ffi.copy(p, path)
        local utime = IS_64_BIT and lib._utime64 or lib._utime32
        if utime(p, buf) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.setmode(file, mode)
        if io.type(file) ~= 'file' then
            error("setmode: invalid file")
        end
        if mode ~= nil and (mode ~= 'text' and mode ~= 'binary') then
            error('setmode: invalid mode')
        end
        mode = (mode == 'text') and 0x4000 or 0x8000
        local prev_mode = lib._setmode(lib._fileno(file), mode)
        if prev_mode == -1 then
            return nil, errno()
        end
        return true, (prev_mode == 0x4000) and 'text' or 'binary'
    end

    local function check_is_dir(path)
        return _M.attributes(path, 'mode') == 'directory' and 1 or 0
    end

    function _M.link(old, new)
        local is_dir = check_is_dir(old)
        if lib.CreateSymbolicLinkW(
                wchar_t(new),
                wchar_t(old), is_dir) ~= 0 then
            return true
        end
        return nil, errno()
    end

    local findfirst
    local findnext
    local wfindfirst
    local wfindnext
    if IS_64_BIT then
        ffi.cdef([[
            typedef struct _finddata64_t {
                uint64_t  attrib;
                uint64_t  time_create;
                uint64_t  time_access;
                uint64_t  time_write;
                uint64_t  size;
                char      name[]] .. MAXPATH ..[[];
            } _finddata_t;
            intptr_t _findfirst64(const char *filespec, _finddata_t *fileinfo);
            int _findnext64(intptr_t handle, _finddata_t *fileinfo);
            int _findclose(intptr_t handle);
            typedef struct _wfinddata_t { //is _wfinddata64_t
                uint64_t  attrib;
                uint64_t  time_create;
                uint64_t  time_access;
                uint64_t  time_write;
                uint64_t  size;
                wchar_t      name[]] .. MAXPATH ..[[];
            } _wfinddata_t;
            intptr_t _wfindfirst64(const wchar_t *filespec, struct _wfinddata_t *fileinfo);  
            int _wfindnext64(intptr_t handle,struct _wfinddata_t *fileinfo);  
                                                              
        ]])
        findfirst = lib._findfirst64
        findnext = lib._findnext64
        wfindfirst = lib._wfindfirst64
        wfindnext = lib._wfindnext64
    else
        ffi.cdef([[
            typedef struct _finddata32_t {
                uint32_t  attrib;
                uint32_t  time_create;
                uint32_t  time_access;
                uint32_t  time_write;
                uint32_t  size;
                char      name[]] .. MAXPATH ..[[];
            } _finddata_t;
            intptr_t _findfirst32(const char* filespec, _finddata_t* fileinfo);
            int _findnext32(intptr_t handle, _finddata_t *fileinfo);
            
            intptr_t _findfirst(const char* filespec, _finddata_t* fileinfo);
            int _findnext(intptr_t handle, _finddata_t *fileinfo);
            
            typedef struct _wfinddata_t {
                uint32_t  attrib;
                uint32_t  time_create;
                uint32_t  time_access;
                uint32_t  time_write;
                uint32_t  size;
                wchar_t      name[]] .. MAXPATH ..[[];
            } _wfinddata_t;
            intptr_t _wfindfirst(  
            const wchar_t *filespec,  
            struct _wfinddata_t *fileinfo   
            );
            intptr_t _wfindfirst32(  
                const wchar_t *filespec,  
                struct _wfinddata_t *fileinfo
            );  
            
            int _wfindnext(  
                intptr_t handle,  
                struct _wfinddata_t *fileinfo   
            );  
            int _wfindnext32(  
                intptr_t handle,  
                struct _wfinddata_t *fileinfo   
            );  
            int _findclose(intptr_t handle);
        ]])
        local ok
        ok,findfirst = pcall(function() return lib._findfirst32 end)
        if not ok then findfirst = lib._findfirst end
        ok,findnext = pcall(function() return lib._findnext32 end)
        if not ok then findnext = lib._findnext end
        ok,wfindfirst = pcall(function() return lib._wfindfirst end)
        if not ok then ok,wfindfirst = pcall(function() return lib._wfindfirst32 end) end
        if not ok then HAVE_WFINDFIRST = false end
        ok,wfindnext = pcall(function() return lib._wfindnext end)
        if not ok then ok,wfindnext = pcall(function() return lib._wfindnext32 end) end
    end

    local function findclose(dentry)
        if dentry and dentry.handle ~= -1 then
            lib._findclose(dentry.handle)
            dentry.handle = -1
        end
    end

    local dir_type = ffi.metatype("struct {intptr_t handle;}", {
        __gc = findclose
    })

    local function close(dir)
        findclose(dir._dentry)
        dir.closed = true
    end

    local function iterator(dir)
        if dir.closed ~= false then error("closed directory") end
        local entry = ffi.new("_finddata_t")
        if not dir._dentry then
            dir._dentry = ffi.new(dir_type)
            dir._dentry.handle = findfirst(dir._pattern, entry)
            if dir._dentry.handle == -1 then
                dir.closed = true
                return nil, errno()
            end
            return ffi_str(entry.name)
        end

        if findnext(dir._dentry.handle, entry) == 0 then
            return ffi_str(entry.name)
        end
        close(dir)
        return nil
    end
    
    local function witerator(dir)
        if dir.closed ~= false then error("closed directory") end
        local entry = ffi.new("_wfinddata_t")
        if not dir._dentry then
            dir._dentry = ffi.new(dir_type)
            local szPattern = win_utf8_to_unicode(dir._pattern);
            dir._dentry.handle = wfindfirst(szPattern, entry)
            if dir._dentry.handle == -1 then
                dir.closed = true
                return nil, errno()
            end
            local szName = win_unicode_to_utf8(entry.name)--, -1, szName, 512);
            return ffi_str(szName)
        end

        if wfindnext(dir._dentry.handle, entry) == 0 then
            local szName = win_unicode_to_utf8(entry.name)--, -1, szName, 512);
            return ffi_str(szName)
        end
        close(dir)
        return nil
    end

    local dirmeta = {__index = {
        next = iterator,
        close = close,
    }}

    function _M.sdir(path)
        if #path > MAXPATH - 2 then
            error('path too long: ' .. path)
        end
        local dir_obj = setmetatable({
            _pattern = path..'/*',
            closed  = false,
        }, dirmeta)
        return iterator, dir_obj
    end
    
    local wdirmeta = {__index = {
        next = witerator,
        close = close,
    }}

    function _M.wdir(path)
        if #path > MAXPATH - 2 then
            error('path too long: ' .. path)
        end
        local dir_obj = setmetatable({
            _pattern = path..'/*',
            closed  = false,
        }, wdirmeta)
        return witerator, dir_obj
    end
    
    function _M.dir(path)
        if _M.unicode then
            return _M.wdir(path)
        else
            return _M.sdir(path)
        end
    end
    
    ffi.cdef([[
        int _fileno(struct FILE *stream);
        int fseek(struct FILE *stream, long offset, int origin);
        long ftell(struct FILE *stream);
        int _locking(int fd, int mode, long nbytes);
    ]])

    local mode_ltype_map = {
        r = 2, -- LK_NBLCK
        w = 2, -- LK_NBLCK
        u = 0, -- LK_UNLCK
    }
    local SEEK_SET = 0
    local SEEK_END = 2

    local function lock(fh, mode, start, len)
        local lkmode = mode_ltype_map[mode]
        if not len or len <= 0 then
            if lib.fseek(fh, 0, SEEK_END) ~= 0 then
                return nil, errno()
            end
            len = lib.ftell(fh)
        end
        if not start or start <= 0 then
            start = 0
        end
        if lib.fseek(fh, start, SEEK_SET) ~= 0 then
            return nil, errno()
        end
        local fd = lib._fileno(fh)
        if lib._locking(fd, lkmode, len) == -1 then
            return nil, errno()
        end
        return true
    end

    function _M.lock(filehandle, mode, start, length)
        if mode ~= 'r' and mode ~= 'w' then
            error("lock: invalid mode")
        end
        if io.type(filehandle) ~= 'file' then
            error("lock: invalid file")
        end
        local ok, err = lock(filehandle, mode, start, length)
        if not ok then
            return nil, err
        end
        return true
    end

    function _M.unlock(filehandle, start, length)
        if io.type(filehandle) ~= 'file' then
            error("unlock: invalid file")
        end
        local ok, err = lock(filehandle, 'u', start, length)
        if not ok then
            return nil, err
        end
        return true
    end
else
    ffi.cdef([[
        char *getcwd(char *buf, size_t size);
        int chdir(const char *path);
        int rmdir(const char *pathname);
        typedef unsigned int mode_t;
        int mkdir(const char *pathname, mode_t mode);
        typedef size_t time_t;
        struct utimebuf {
            time_t actime;
            time_t modtime;
        };
        int utime(const char *file, const struct utimebuf *times);
        int link(const char *oldpath, const char *newpath);
        int symlink(const char *oldpath, const char *newpath);
    ]])

    function _M.chdir(path)
        if lib.chdir(path) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.currentdir()
        local size = MAXPATH
        while true do
            local buf = ffi.new("char[?]", size)
            if lib.getcwd(buf, size) ~= nil then
                return ffi_str(buf)
            end
            local err = errno()
            if err ~= ERANGE then
                return nil, err
            end
            size = size * 2
        end
    end

    function _M.mkdir(path, mode)
        if lib.mkdir(path, mode or 509) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.rmdir(path)
        if lib.rmdir(path) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.touch(path, actime, modtime)
        local buf

        if type(actime) == "number" then
            modtime = modtime or actime
            buf = ffi.new("struct utimebuf")
            buf.actime  = actime
            buf.modtime = modtime
        end

        local p = ffi.new("unsigned char[?]", #path + 1)
        ffi.copy(p, path)

        if lib.utime(p, buf) == 0 then
            return true
        end
        return nil, errno()
    end

    function _M.setmode()
        return true, "binary"
    end

    function _M.link(old, new, symlink)
        local f = symlink and lib.symlink or lib.link
        if f(old, new) == 0 then
            return true
        end
        return nil, errno()
    end

    local dirent_def
    if OS == 'OSX' or OS == 'BSD' then
        dirent_def = [[
            /* _DARWIN_FEATURE_64_BIT_INODE is NOT defined here? */
            struct dirent {
                uint32_t d_ino;
                uint16_t d_reclen;
                uint8_t  d_type;
                uint8_t  d_namlen;
                char d_name[256];
            };
        ]]
    else
        dirent_def = [[
            struct dirent {
                int64_t           d_ino;
                size_t           d_off;
                unsigned short  d_reclen;
                unsigned char   d_type;
                char            d_name[256];
            };
        ]]
    end
    ffi.cdef(dirent_def .. [[
        typedef struct  __dirstream DIR;
        DIR *opendir(const char *name);
        struct dirent *readdir(DIR *dirp);
        int closedir(DIR *dirp);
    ]])

    local function close(dir)
        if dir._dentry ~= nil then
            lib.closedir(dir._dentry)
            dir._dentry = nil
            dir.closed = true
        end
    end

    local function iterator(dir)
        if dir.closed ~= false then error("closed directory") end

        local entry = lib.readdir(dir._dentry)
        if entry ~= nil then
            return ffi_str(entry.d_name)
        else
            close(dir)
            return nil
        end
    end

    local dir_obj_type = ffi.metatype([[
        struct {
            DIR *_dentry;
            bool closed;
        }
    ]],
    {__index = {
        next = iterator,
        close = close,
    }, __gc = close
    })

    function _M.dir(path)
        local dentry = lib.opendir(path)
        if dentry == nil then
            error("cannot open "..path.." : "..errno())
        end
        local dir_obj = ffi.new(dir_obj_type)
        dir_obj._dentry = dentry
        dir_obj.closed = false;
        return iterator, dir_obj
    end

    local SEEK_SET = 0
    local F_SETLK = (OS == 'Linux') and 6 or 8
    local mode_ltype_map
    local flock_def
    if OS == 'Linux' then
        flock_def = [[
            struct flock {
                short int l_type;
                short int l_whence;
                int64_t l_start;
                int64_t l_len;
                int l_pid;
            };
        ]]
        mode_ltype_map = {
            r = 0, -- F_RDLCK
            w = 1, -- F_WRLCK
            u = 2, -- F_UNLCK
        }
    else
        flock_def = [[
            struct flock {
                int64_t l_start;
                int64_t l_len;
                int32_t l_pid;
                short   l_type;
                short   l_whence;
            };
        ]]
        mode_ltype_map = {
            r = 1, -- F_RDLCK
            u = 2, -- F_UNLCK
            w = 3, -- F_WRLCK
        }
    end

    ffi.cdef(flock_def..[[
        int fileno(struct FILE *stream);
        int fcntl(int fd, int cmd, ... /* arg */ );
        int unlink(const char *path);
    ]])

    local function lock(fd, mode, start, len)
        local flock = ffi.new('struct flock')
        flock.l_type = mode_ltype_map[mode]
        flock.l_whence = SEEK_SET
        flock.l_start = start or 0
        flock.l_len = len or 0
        if lib.fcntl(fd, F_SETLK, flock) == -1 then
            return nil, errno()
        end
        return true
    end

    function _M.lock(filehandle, mode, start, length)
        if mode ~= 'r' and mode ~= 'w' then
            error("lock: invalid mode")
        end
        if io.type(filehandle) ~= 'file' then
            error("lock: invalid file")
        end
        local fd = lib.fileno(filehandle)
        local ok, err = lock(fd, mode, start, length)
        if not ok then
            return nil, err
        end
        return true
    end

    function _M.unlock(filehandle, start, length)
        if io.type(filehandle) ~= 'file' then
            error("unlock: invalid file")
        end
        local fd = lib.fileno(filehandle)
        local ok, err = lock(fd, 'u', start, length)
        if not ok then
            return nil, err
        end
        return true
    end
end

-- lock related
local dir_lock_struct
local create_lockfile
local delete_lockfile

if OS == 'Windows' then
    ffi.cdef([[
        typedef const wchar_t* LPCWSTR;
        typedef struct _SECURITY_ATTRIBUTES {
            DWORD nLength;
            void *lpSecurityDescriptor;
            int bInheritHandle;
        } SECURITY_ATTRIBUTES;
        typedef SECURITY_ATTRIBUTES *LPSECURITY_ATTRIBUTES;
        void *CreateFileW(
            LPCWSTR lpFileName,
            DWORD dwDesiredAccess,
            DWORD dwShareMode,
            LPSECURITY_ATTRIBUTES lpSecurityAttributes,
            DWORD dwCreationDisposition,
            DWORD dwFlagsAndAttributes,
            void *hTemplateFile
        );

        int CloseHandle(void *hObject);
    ]])

    local GENERIC_WRITE = 0x40000000
    local CREATE_NEW = 1
    local FILE_NORMAL_DELETE_ON_CLOSE = 0x04000080

    dir_lock_struct = 'struct {void *lockname;}'

    function create_lockfile(dir_lock, _, lockname)
        lockname = wchar_t(lockname)
        dir_lock.lockname = lib.CreateFileW(lockname, GENERIC_WRITE, 0, nil, CREATE_NEW,
                FILE_NORMAL_DELETE_ON_CLOSE, nil)
        return dir_lock.lockname ~= ffi.cast('void*', -1)
    end

    function delete_lockfile(dir_lock)
        return lib.CloseHandle(dir_lock.lockname)
    end
else
    dir_lock_struct = 'struct {char *lockname;}'
    function create_lockfile(dir_lock, path, lockname)
        dir_lock.lockname = ffi.new('char[?]', #lockname + 1)
        ffi.copy(dir_lock.lockname, lockname)
        return lib.symlink(path, lockname) == 0
    end

    function delete_lockfile(dir_lock)
        return lib.unlink(dir_lock.lockname)
    end
end

local function unlock_dir(dir_lock)
    if dir_lock.lockname ~= nil then
        dir_lock:delete_lockfile()
        dir_lock.lockname = nil
    end
    return true
end

local dir_lock_type = ffi.metatype(dir_lock_struct,
    {__gc = unlock_dir,
    __index = {
        free = unlock_dir,
        create_lockfile = create_lockfile,
        delete_lockfile = delete_lockfile,
    }}
)

function _M.lock_dir(path, _)
    -- It's interesting that the lock_dir from vanilla lfs just ignores second paramter.
    -- So, I follow this behavior too :)
    local dir_lock = ffi.new(dir_lock_type)
    local lockname = path .. '/lockfile.lfs'
    if not dir_lock:create_lockfile(path, lockname) then
        return nil, errno()
    end
    return dir_lock
end

-- stat related
local stat_func
local lstat_func
if OS == 'Linux' then
    ffi.cdef([[
        long syscall(int number, ...);
    ]])
    local ARCH = ffi.arch
    -- Taken from justincormack/ljsyscall
    local stat_syscall_num
    local lstat_syscall_num
    if ARCH == 'x64' then
        ffi.cdef([[
            typedef struct {
                unsigned long   st_dev;
                unsigned long   st_ino;
                unsigned long   st_nlink;
                unsigned int    st_mode;
                unsigned int    st_uid;
                unsigned int    st_gid;
                unsigned int    __pad0;
                unsigned long   st_rdev;
                long            st_size;
                long            st_blksize;
                long            st_blocks;
                unsigned long   st_atime;
                unsigned long   st_atime_nsec;
                unsigned long   st_mtime;
                unsigned long   st_mtime_nsec;
                unsigned long   st_ctime;
                unsigned long   st_ctime_nsec;
                long            __unused[3];
            } lfs_stat;
        ]])
        stat_syscall_num = 4
        lstat_syscall_num = 6
    elseif ARCH == 'x86' then
        ffi.cdef([[
            typedef struct {
                unsigned long long      st_dev;
                unsigned char   __pad0[4];
                unsigned long   __st_ino;
                unsigned int    st_mode;
                unsigned int    st_nlink;
                unsigned long   st_uid;
                unsigned long   st_gid;
                unsigned long long      st_rdev;
                unsigned char   __pad3[4];
                long long       st_size;
                unsigned long   st_blksize;
                unsigned long long      st_blocks;
                unsigned long   st_atime;
                unsigned long   st_atime_nsec;
                unsigned long   st_mtime;
                unsigned int    st_mtime_nsec;
                unsigned long   st_ctime;
                unsigned long   st_ctime_nsec;
                unsigned long long      st_ino;
            } lfs_stat;
        ]])
        stat_syscall_num = IS_64_BIT and 106 or 195
        lstat_syscall_num = IS_64_BIT and 107 or 196
    elseif ARCH == 'arm' then
        if IS_64_BIT then
            ffi.cdef([[
                typedef struct {
                    unsigned long   st_dev;
                    unsigned long   st_ino;
                    unsigned int    st_mode;
                    unsigned int    st_nlink;
                    unsigned int    st_uid;
                    unsigned int    st_gid;
                    unsigned long   st_rdev;
                    unsigned long   __pad1;
                    long            st_size;
                    int             st_blksize;
                    int             __pad2;
                    long            st_blocks;
                    long            st_atime;
                    unsigned long   st_atime_nsec;
                    long            st_mtime;
                    unsigned long   st_mtime_nsec;
                    long            st_ctime;
                    unsigned long   st_ctime_nsec;
                    unsigned int    __unused4;
                    unsigned int    __unused5;
                } lfs_stat;
            ]])
            stat_syscall_num = 106
            lstat_syscall_num = 107
        else
            ffi.cdef([[
                typedef struct {
                    unsigned long long      st_dev;
                    unsigned char   __pad0[4];
                    unsigned long   __st_ino;
                    unsigned int    st_mode;
                    unsigned int    st_nlink;
                    unsigned long   st_uid;
                    unsigned long   st_gid;
                    unsigned long long      st_rdev;
                    unsigned char   __pad3[4];
                    long long       st_size;
                    unsigned long   st_blksize;
                    unsigned long long      st_blocks;
                    unsigned long   st_atime;
                    unsigned long   st_atime_nsec;
                    unsigned long   st_mtime;
                    unsigned int    st_mtime_nsec;
                    unsigned long   st_ctime;
                    unsigned long   st_ctime_nsec;
                    unsigned long long      st_ino;
                } lfs_stat;
            ]])
            stat_syscall_num = 195
            lstat_syscall_num = 196
        end
    elseif ARCH == 'ppc' or ARCH == 'ppcspe' then
        ffi.cdef([[
            typedef struct {
                unsigned long long st_dev;
                unsigned long long st_ino;
                unsigned int    st_mode;
                unsigned int    st_nlink;
                unsigned int    st_uid;
                unsigned int    st_gid;
                unsigned long long st_rdev;
                unsigned long long __pad1;
                long long       st_size;
                int             st_blksize;
                int             __pad2;
                long long       st_blocks;
                int             st_atime;
                unsigned int    st_atime_nsec;
                int             st_mtime;
                unsigned int    st_mtime_nsec;
                int             st_ctime;
                unsigned int    st_ctime_nsec;
                unsigned int    __unused4;
                unsigned int    __unused5;
            } lfs_stat;
        ]])
        stat_syscall_num = IS_64_BIT and 106 or 195
        lstat_syscall_num = IS_64_BIT and 107 or 196
    elseif ARCH == 'mips' or ARCH == 'mipsel' then
        ffi.cdef([[
            typedef struct {
                unsigned long   st_dev;
                unsigned long   __st_pad0[3];
                unsigned long long      st_ino;
                mode_t          st_mode;
                nlink_t         st_nlink;
                uid_t           st_uid;
                gid_t           st_gid;
                unsigned long   st_rdev;
                unsigned long   __st_pad1[3];
                long long       st_size;
                time_t          st_atime;
                unsigned long   st_atime_nsec;
                time_t          st_mtime;
                unsigned long   st_mtime_nsec;
                time_t          st_ctime;
                unsigned long   st_ctime_nsec;
                unsigned long   st_blksize;
                unsigned long   __st_pad2;
                long long       st_blocks;
                long __st_padding4[14];
            } lfs_stat;
        ]])
        stat_syscall_num = IS_64_BIT and 4106 or 4213
        lstat_syscall_num = IS_64_BIT and 4107 or 4214
    end

    if stat_syscall_num then
        stat_func = function(filepath, buf)
            return lib.syscall(stat_syscall_num, filepath, buf)
        end
        lstat_func = function(filepath, buf)
            return lib.syscall(lstat_syscall_num, filepath, buf)
        end
    else
        ffi.cdef('typedef struct {} lfs_stat;')
        stat_func = function() error("TODO support other Linux architectures") end
        lstat_func = stat_func
    end
elseif OS == 'Windows' then
    ffi.cdef([[
        typedef __int64 __time64_t;
        typedef struct {
            unsigned int        st_dev;
            unsigned short      st_ino;
            unsigned short      st_mode;
            short               st_nlink;
            short               st_uid;
            short               st_gid;
            unsigned int        st_rdev;
            __int64             st_size;
            __time64_t          st_atime;
            __time64_t          st_mtime;
            __time64_t          st_ctime;
        } lfs_stat;

        int _stat64(const char *path, lfs_stat *buffer);
        int _wstat64(const wchar_t *path, lfs_stat *buffer);      
    ]])

    stat_func = function(filepath, buf)
        if _M.unicode then
            local szfp = win_utf8_to_unicode(filepath);
            return lib._wstat64(szfp, buf)
        else
            return lib._stat64(filepath, buf)
        end
    end
    lstat_func = stat_func
elseif OS == 'OSX' then
    ffi.cdef([[
        struct lfs_timespec {
            time_t tv_sec;
            long tv_nsec;
        };
        typedef struct {
            uint32_t           st_dev;
            uint16_t          st_mode;
            uint16_t         st_nlink;
            uint64_t         st_ino;
            uint32_t           st_uid;
            uint32_t           st_gid;
            uint32_t           st_rdev;
            struct lfs_timespec st_atimespec;
            struct lfs_timespec st_mtimespec;
            struct lfs_timespec st_ctimespec;
            struct lfs_timespec st_birthtimespec;
            int64_t           st_size;
            int64_t        st_blocks;
            int32_t       st_blksize;
            uint32_t        st_flags;
            uint32_t        st_gen;
            int32_t         st_lspare;
            int64_t         st_qspare[2];
        } lfs_stat;
        int stat64(const char *path, lfs_stat *buf);
        int lstat64(const char *path, lfs_stat *buf);
    ]])
    stat_func = lib.stat64
    lstat_func = lib.lstat64
elseif OS == 'BSD' then
    ffi.cdef([[
        struct lfs_timespec {
            time_t tv_sec;
            long tv_nsec;
        };
        typedef struct {
            uint32_t           st_dev;
            uint32_t         st_ino;
            uint16_t          st_mode;
            uint16_t         st_nlink;
            uint32_t           st_uid;
            uint32_t           st_gid;
            uint32_t           st_rdev;
            struct lfs_timespec st_atimespec;
            struct lfs_timespec st_mtimespec;
            struct lfs_timespec st_ctimespec;
            int64_t           st_size;
            int64_t        st_blocks;
            int32_t       st_blksize;
            uint32_t        st_flags;
            uint32_t        st_gen;
            int32_t         st_lspare;
            struct lfs_timespec st_birthtimespec;
        } lfs_stat;
        int stat(const char *path, lfs_stat *buf);
        int lstat(const char *path, lfs_stat *buf);
    ]])
    stat_func = lib.stat
    lstat_func = lib.lstat
else
    ffi.cdef('typedef struct {} lfs_stat;')
    stat_func = function() error('TODO: support other posix system') end
    lstat_func = stat_func
end

local STAT = {
    FMT   = 0xF000,
    FSOCK = 0xC000,
    FLNK  = 0xA000,
    FREG  = 0x8000,
    FBLK  = 0x6000,
    FDIR  = 0x4000,
    FCHR  = 0x2000,
    FIFO  = 0x1000,
}

local ftype_name_map = {
    [STAT.FREG]  = 'file',
    [STAT.FDIR]  = 'directory',
    [STAT.FLNK]  = 'link',
    [STAT.FSOCK] = 'socket',
    [STAT.FCHR]  = 'char device',
    [STAT.FBLK]  = "block device",
    [STAT.FIFO]  = "named pipe",
}

local function mode_to_ftype(mode)
    local ftype = band(mode, STAT.FMT)
    return ftype_name_map[ftype] or 'other'
end

local function mode_to_perm(mode)
    local perm_bits = band(mode, tonumber(777, 8))
    local perm = new_tab(9, 0)
    local i = 9
    while i > 0 do
        local perm_bit = band(perm_bits, 7)
        perm[i] = (band(perm_bit, 1) > 0 and 'x' or '-')
        perm[i-1] = (band(perm_bit, 2) > 0 and 'w' or '-')
        perm[i-2] = (band(perm_bit, 4) > 0 and 'r' or '-')
        i = i - 3
        perm_bits = rshift(perm_bits, 3)
    end
    return concat(perm)
end

local function time_or_timespec(time, timespec)
    local t = tonumber(time)
    if not t and timespec then
        t = tonumber(timespec.tv_sec)
    end
    return t
end

local attr_handlers = {
    access = function(st) return time_or_timespec(st.st_atime, st.st_atimespec) end,
    blksize = function(st) return tonumber(st.st_blksize) end,
    blocks = function(st) return tonumber(st.st_blocks) end,
    change = function(st) return time_or_timespec(st.st_ctime, st.st_ctimespec) end,
    dev = function(st) return tonumber(st.st_dev) end,
    gid = function(st) return tonumber(st.st_gid) end,
    ino = function(st) return tonumber(st.st_ino) end,
    mode = function(st) return mode_to_ftype(st.st_mode) end,
    modification = function(st) return time_or_timespec(st.st_mtime, st.st_mtimespec) end,
    nlink = function(st) return tonumber(st.st_nlink) end,
    permissions = function(st) return mode_to_perm(st.st_mode) end,
    rdev = function(st) return tonumber(st.st_rdev) end,
    size = function(st) return tonumber(st.st_size) end,
    uid = function(st) return tonumber(st.st_uid) end,
}
local mt = {
    __index = function(self, attr_name)
        local func = attr_handlers[attr_name]
        return func and func(self)
    end
}
local stat_type = ffi.metatype('lfs_stat', mt)

-- Add target field for symlinkattributes, which is the absolute path of linked target
local get_link_target_path
if OS == 'Windows' then
    local ENOSYS = 40
    function get_link_target_path()
        return nil, "could not obtain link target: Function not implemented ",ENOSYS
    end
else

    ffi.cdef('ssize_t readlink(const char *path, char *buf, size_t bufsize);')
    local EINVAL = 22
    function get_link_target_path(link_path, statbuf)
        local size = statbuf.st_size
        size = size == 0 and MAXPATH or size
        local buf = ffi.new('char[?]', size + 1)
        local read = lib.readlink(link_path, buf, size)
        if read == -1 then
            return nil, "could not obtain link target: "..errno(), ffi.errno()
        end
        if read > size then
            return nil, "not enought size for readlink: "..errno(), ffi.errno()
        end
        buf[size] = 0
        return ffi_str(buf)
    end
end

local buf = ffi.new(stat_type)
local function attributes(filepath, attr, follow_symlink)
    local func = follow_symlink and stat_func or lstat_func
    if func(filepath, buf) == -1 then
        return nil, string.format("cannot obtain information from file '%s' : %s",tostring(filepath),errno()), ffi.errno()
    end

    local atype = type(attr)
    if atype == 'string' then
        local value, err, errn
        if attr == 'target' and not follow_symlink then
            value, err, errn = get_link_target_path(filepath, buf)
            return value, err, errn
        else
            value = buf[attr]
        end
        if value == nil then
            error("invalid attribute name '" .. attr .. "'")
        end
        return value
    else
        local tab = (atype == 'table') and attr or {}
        for k, _ in pairs(attr_handlers) do
            tab[k] = buf[k]
        end
        if not follow_symlink then
            tab.target = get_link_target_path(filepath, buf)
        end
        return tab
    end
end

function _M.attributes(filepath, attr)
    return attributes(filepath, attr, true)
end

function _M.symlinkattributes(filepath, attr)
    return attributes(filepath, attr, false)
end

_M.unicode = HAVE_WFINDFIRST
_M.unicode_errors = false
--this would error with _M.unicode_errors = true
--local cad = string.char(0xE0,0x80,0x80)--,0xFD,0xFF)

return _M
