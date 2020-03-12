local serialize = require("serialize")
local filesystem = require("filesystem")
local requireUtils = require("require_utils")

local utils = {}

utils.serialize = serialize.serialize
utils.unserialize = serialize.unserialize

function utils.stripByteOrderMark(s)
    if s:byte(1) == 0xef and s:byte(2) == 0xbb and s:byte(3) == 0xbf then
        return s:sub(4, #s)
    end

    return s
end

function utils.rectangle(x, y, width, height)
    return {x = x, y = y, width = width, height = height}
end

function utils.point(x, y)
    return {x = x, y = y, width = 1, height = 1}
end

function utils.rectangleBounds(rectangles)
    local tlx, tly = math.huge(), math.huge()
    local brx, bry = -math.huge(), -math.huge()

    for i, rect in ipairs(rectangles) do
        tlx = math.min(tlx, rect.x)
        tly = math.min(tly, rect.y)

        brx = math.max(brx, rect.x + rect.width)
        bry = math.max(bry, rect.y + rect.height)
    end

    return tlx, tly, brx, bry
end

function utils.coverRectangles(rectangles)
    local tlx, tly, brx, bry = utils.rectangleBounds(rectangles)

    return tlx, tly, brx - tlx, bry - tly
end

-- Does the bounds and covering manually, reduces table construction
function utils.coverTriangle(x1, y1, x2, y2, x3, y3)
    local tlx = math.min(x1, x2, x3)
    local tly = math.min(y1, y2, y3)
    local brx = math.max(x1, x2, x3)
    local bry = math.max(y1, y2, y3)

    return tlx, tly, brx - tlx, bry - tly
end

function utils.aabbCheck(r1, r2)
    return not (r2.x >= r1.x + r1.width or r2.x + r2.width <= r1.x or r2.y >= r1.y + r1.height or r2.y + r2.height <= r1.y)
end

function utils.aabbCheckInline(x1, y1, w1, h1, x2, y2, w2, h2)
    return not (x2 >= x1 + w1 or x2 + w2 <= x1 or y2 >= y1 + h1 or y2 + h2 <= y1)
end

function utils.getFileHandle(path, mode, internal)
    if internal then
        return love.filesystem.newFile(path, mode:gsub("b", ""))

    else
        return io.open(path, mode)
    end
end


function utils.readAll(path, mode, internal)
    local file = utils.getFileHandle(path, mode or "rb", internal)

    if file then
        local res = internal and file:read() or file:read("*a")

        file:close()

        return res
    end
end

function utils.newImage(path, internal)
    if internal then
        return love.graphics.newImage(path)

    else
        local fileData, err = love.filesystem.newFileData(utils.readAll(path, "rb", internal), "placeholder.png")

        if fileData then
            local imageData = love.image.newImageData(fileData)
            return love.graphics.newImage(imageData)
        end
    end
end

function utils.trim(s)
    return string.match(s, "^%s*(.*%S)") or ""
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
    color := match("^#?([0-9a-fA-F]+)$")

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
        res[key] = res[key] or {}

        table.insert(res[key], v)
    end

    return res
end

function utils.concat(...)
    local res = {}

    for i, t in ipairs({...}) do
        for j, v in ipairs(t) do
            table.insert(res, v)
        end
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
    local m = n % d

    return m == 0 and d or m
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

function utils.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

-- Add all of require utils into utils
for k, v <- requireUtils do
    utils[k] = v
end


-- Add all of filesystem helper into utils
for k, v <- filesystem do
    utils[k] = v
end

-- Add filesystem specific helper methods
local osFilename = love.system.getOS():lower():gsub(" ", "_")
local osHelper = require("os_helpers." .. osFilename)

function utils.getProcessId()
    return osHelper.getProcessId and osHelper.getProcessId()
end

return utils