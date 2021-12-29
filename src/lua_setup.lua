-- Setting up globals for a new Lua environment (main.lua or conf.lua)

local ffi = require("ffi")

local path = "selene/selene/lib/?.lua;selene/selene/lib/?/init.lua;?/?.lua;" .. love.filesystem.getRequirePath()
love.filesystem.setRequirePath(path)

-- love.system might not exist yet
if ffi and ffi.os == "OSX" then
    package.cpath = package.cpath .. ";" .. love.filesystem.getSourceBaseDirectory() .. "/?.so"
end

-- Load faster unpack function
require("lib.fast_unpack")

-- Keeping it here since it is an option, and seems to make a difference at some points
-- Attempt to expose to config option at some point
--[[
_G._selene = {}
_G._selene.notypecheck = true
]]

require("selene").load()
require("selene/selene/wrappers/searcher/love2d/searcher").load()