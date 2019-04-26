--[==[

Simple version parsing library for versions
of the format "vX.Y.Z.P".
Allows creating comparable version objects.
Use tostring() to turn a version object back into a string.

Usage:
  local v = require("version_parser")
  print(v("v1.4.6") < v("v1.4.7"))

Author: Vexatos


MIT License

Copyright (c) 2019 Vexatos

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

local version = {}

local library_mt = {}
local vmt = {}

function vmt.__eq(v, o)
    if type(v) ~= "table" or type(o) ~= "table" or #v ~= #o then
        return false
    end
    for i = 1, #v do
        if v[i] ~= o[i] then
            return false
        end
    end
    return true
end

function vmt.__lt(v, o)
    if type(v) ~= "table" or type(o) ~= "table" then
        return false
    end
    for i = 1, #v do
        if not o[i] then
            return false
        elseif v[i] < o[i] then
            return true
        elseif v[i] > o[i] then
            return false
        end
    end
    return o[#v + 1] and 0 < o[#v + 1]
end

function vmt.__le(v, o)
    if type(v) ~= "table" or type(o) ~= "table" then
        return false
    end
    for i = 1, #v do
        if not o[i] then
            return v[i] == 0
        elseif v[i] < o[i] then
            return true
        elseif v[i] > o[i] then
            return false
        end
    end
    return true
end

function vmt.__tostring(v)
    return table.concat(v, ".")
end

function library_mt.__call(lib, s)
    if type(s) ~= "string" or not s:find("%d[%d.]*") then
        return nil, "invalid version string: " .. s
    end
    local newv = {}
    for subv in s:gsub("^%a*(%d[%d.]*).*", "%1"):gmatch("[^.]+") do
        nv = tonumber(subv)
        if not nv then
            return nil, "invalid version string: " .. s
        end
        table.insert(newv, nv)
    end
    setmetatable(newv, vmt)
    return newv
end

setmetatable(version, library_mt)

return version