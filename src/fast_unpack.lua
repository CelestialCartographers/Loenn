--[==[

Faster unpack for Lua 5.1. Uses a cache of functions which are each optimized
for one specific number of varargs.
Improves performance by up to two orders of magnitude in LuaJIT.

Author: Vexatos


MIT License

Copyright (c) 2021 Vexatos

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

]==]

local fast_unpack = {}
local unpack_mt = {}

function unpack_mt.__call(u, tbl)
    local len = #tbl

    if not u[len] then
        local values = {}

        for i = 1, len do
            values[i] = string.format("t[%d]", i)
        end

        u[len] = assert(load(string.format("return function(t) return %s end", table.concat(values, ","))))()
    end

    return u[len](tbl)
end

setmetatable(fast_unpack, unpack_mt)

unpack_orig = unpack
unpack = fast_unpack
