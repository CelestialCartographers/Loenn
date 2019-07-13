local serialize = require("serialize")
local filesystem = require("filesystem")

local utils = {}

utils.serialize = serialize.serialize
utils.unserialize = serialize.unserialize

function utils.stripByteOrderMark(s)
    if s:byte(1) == 0xef and s:byte(2) == 0xbb and s:byte(3) == 0xbf then
        return s:sub(4, #s)
    end

    return s
end

function utils.aabbCheck(r1, r2)
    return not (r2.x >= r1.x + r1.width or r2.x + r2.width <= r1.x or r2.y >= r1.y + r1.height or r2.y + r2.height <= r1.y)
end

function utils.getFileHandle(path, mode, internal)
    if internal then
        return love.filesystem.newFile(path, mode:gsub("b", ""))
        
    else
        return io.open(path, mode)
    end
end


function utils.readAll(path, mode, internal)
    local mode = mode or "rb"
    local file = utils.getFileHandle(path, mode, internal)

    if file then
        local res = internal and file:read() or file:read("*a")

        file:close()

        return res
    end
end

function utils.humanizeVariableName(name)
    local res = name

    res := gsub("_", " ")
    res := gsub("/", " ")

    res := gsub("(%l)(%u)", function(a, b) return a .. " " .. b end)
    res := gsub("(%a)(%a*)", function(a, b) return string.upper(a) .. b end)

    res := gsub("%s+", " ")
    res := match("^%s*(.*)%s*$")

    return res
end

function utils.parseHexColor(color)
    local color := match("^#?([0-9a-fA-F]+)$")

    if color and #color == 6 then
        local number = tonumber(color, 16)
        local r, g, b = number / 256^2 % 256, number / 256 % 256, number % 256

        return true, r / 255, g / 255, b / 255
    end

    return false, 0, 0, 0
end

function utils.typeof(v)
    local typ = type(v)

    if typ == "table" and v._type then
        return v._type

    else
        return typ
    end
end

function utils.group(t, by)
    local res = {}

    for k, v <- t do
        local key = by(k, v)
        res[key] = res[key] or $()
        
        res[key] += v
    end

    return res
end

utils.countKeys = serialize.countKeys

-- Return the 1 index based tile indices for the coordinates
function utils.pixelsToTiles(x, y)
    return math.floor(x / 8) + 1, math.floor(y / 8) + 1
end

function utils.getRoomAtCoords(x, y, map)
    for i, room <- map.rooms do
        if x >= room.x and x <= room.x + room.width and y >= room.y and y <= room.y + room.height then
            return room
        end
    end

    return false
end

function utils.mod1(n, d)
    m = n % d

    return m == 0 and d or m
end

-- Clear the cache of a required library
function utils.unrequire(lib)
    package.loaded[lib] = nil
end

-- Clear the cache and return a new uncached version of the library
-- Highly unrecommended to use this for anything
function utils.rerequire(lib)
    utils.unrequire(lib)

    return require(lib)
end

function utils.setRandomSeed(v)
    if type(v) == "number" then
        math.randomseed(v)

    elseif type(v) == "string" and #v >= 1 then
        local s = string.byte(v, 1)

        for i = 2, #v do
            s *= 256
            s += string.byte(v)
        end

        math.randomseed(s)
    end
end

function utils.deepcopy(v)
    if type(v) == "table" then
        local res = {}

        for key, value <- v do
            res[key] = utils.deepcopy(value)
        end

        return res

    else
        return v
    end
end

-- Add all of filesystem helper into utils
for k, v <- filesystem do
    utils[k] = v
end

-- Add filesystem specific helper methods
local osFilename = love.system.getOS():lower():gsub(" ", "_")
local osHelper = require("os_helpers/" .. osFilename)

function utils.getProcessId()
    return osHelper.getProcessId and osHelper.getProcessId()
end

return utils