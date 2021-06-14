local serialize = require("serialize")
local filesystem = require("filesystem")
local requireUtils = require("require_utils")
local xnaColors = require("xna_colors")
local bit = require("bit")

local rectangles = require("structs/rectangle")

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
    return rectangles.create(x, y, width, height)
end

function utils.point(x, y)
    return rectangles.create(x, y, 1, 1)
end

function utils.rectangleBounds(rectangles)
    local tlx, tly = math.huge, math.huge
    local brx, bry = -math.huge, -math.huge

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

function utils.intersection(r1, r2)
    local x = math.max(r1.x, r2.x)
    local y = math.max(r1.y, r2.y)
    local width = math.min(r1.x + r1.width, r2.x + r2.width) - x
    local height = math.min(r1.y + r1.height, r2.y + r2.height) - y

    return width > 0 and height > 0 and utils.rectangle(x, y, width, height) or nil
end

function utils.intersectionBounds(r1, r2)
    local tlx = math.max(r1.x, r2.x)
    local tly = math.max(r1.y, r2.y)
    local brx = math.min(r1.x + r1.width, r2.x + r2.width)
    local bry = math.min(r1.y + r1.height, r2.y + r2.height)

    return tlx, tly, brx, bry
end

function utils.subtractRectangle(r1, r2)
    local tlx, tly, brx, bry = utils.intersectionBounds(r1, r2)

    if tlx >= brx or tly >= bry  then
        -- No intersection
        return {r1}
    end

    local remaining = {}

    -- Left rectangle
    if tlx > r1.x then
        table.insert(remaining, utils.rectangle(r1.x, r1.y, tlx - r1.x, r1.height))
    end

    -- Right rectangle
    if brx < r1.x + r1.width then
        table.insert(remaining, utils.rectangle(brx, r1.y, r1.x + r1.width - brx, r1.height))
    end

    -- Top rectangle
    if tly > r1.y then
        table.insert(remaining, utils.rectangle(tlx, r1.y, brx - tlx, tly - r1.y))
    end

    -- Bottom rectangle
    if bry < r1.y + r1.height then
        table.insert(remaining, utils.rectangle(tlx, bry, brx - tlx, r1.y + r1.height - bry))
    end

    return remaining
end

function utils.getFileHandle(path, mode, internal)
    if internal then
        return love.filesystem.newFile(path, mode:gsub("b", ""))

    else
        return io.open(path, mode)
    end
end

local function readAll(path, mode, internal)
    local file = utils.getFileHandle(path, mode or "rb", internal)

    if file then
        local res = internal and file:read() or file:read("*a")

        file:close()

        return res
    end
end

function utils.readAll(path, mode, internal)
    -- Try both if not specified
    if internal == nil then
        return readAll(path, mode, true) or readAll(path, mode, false)

    else
        return readAll(path, mode, internal)
    end
end

function utils.newImage(path, internal)
    if internal then
        return love.graphics.newImage(path)

    else
        local fileData, err = love.filesystem.newFileData(utils.readAll(path, "rb", internal), "placeholder.png")

        if fileData then
            local imageData = love.image.newImageData(fileData)
            local image = love.graphics.newImage(imageData)

            return image, imageData
        end
    end
end

function utils.trim(s)
    return string.match(s, "^%s*(.*%S)") or ""
end

function utils.startsWith(s, start)
    return s:sub(1, #start) == start
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

function utils.unbackslashify(text)
    return text:gsub("\\n", "\n")
end

function utils.convertToUnixPath(path)
    return path:gsub("\\", "/")
end

function utils.parseHexColor(color)
    color := match("^#?([0-9a-fA-F]+)$")

    if color and #color == 6 then
        local number = tonumber(color, 16)
        local r, g, b = math.floor(number / 256^2) % 256, math.floor(number / 256) % 256, math.floor(number) % 256

        return true, r / 255, g / 255, b / 255
    end

    return false, 0, 0, 0
end

function utils.rgbToHex(r, g, b)
    local r8 = math.floor(r * 255 + 0.5)
    local g8 = math.floor(g * 255 + 0.5)
    local b8 = math.floor(b * 255 + 0.5)
    local number = r8 * 256^2 + g8 * 256 + b8

    return string.format("%06x", number)
end

-- Based on implementation from Love2d wiki
function utils.hsvToRgb(h, s, v)
    if s <= 0 then
        return v, v, v
    end

    h = h * 6

    local c = v * s
    local x = (1 - math.abs((h % 2) - 1)) * c
    local m, r, g, b = v - c, 0, 0, 0

    if h < 1 then
        r, g, b = c, x, 0

    elseif h < 2 then
        r, g, b = x, c, 0

    elseif h < 3 then
        r, g, b = 0, c, x

    elseif h < 4 then
        r, g, b = 0, x, c

    elseif h < 5 then
        r, g, b = x, 0, c

    else
        r, g, b = c, 0, x
    end

    return r + m, g + m, b + m
end

-- Based on implementation from internet
function utils.rgbToHsv(r, g, b)
    local hue, saturation, value

    local minimumValue = math.min(r, g, b)
    local maximumValue = math.max(r, g, b)
    local deltaValue = maximumValue - minimumValue

    if minimumValue == maximumValue then
        hue = 0

    elseif r == maximumValue then
        hue = (60 / 360) * (g - b) / deltaValue + 360 / 360

    elseif g == maximumValue then
        hue = (60 / 360) * (b - r) / deltaValue + 120 / 360

    else
        hue = (60 / 360) * (r - g) / deltaValue + 240 / 360
    end

    -- Make sure hue is not negative or above 1
    hue = (hue + 1) % 1

    if maximumValue == 0 then
        saturation = 0

    else
        saturation = deltaValue / maximumValue
    end

    value = maximumValue

    return hue, saturation, value
end

-- Get color in various formats, return as table
function utils.getColor(color)
    local colorType = type(color)

    if colorType == "string" then
        -- Check XNA colors, otherwise parse as hex color
        if xnaColors[color] then
            return xnaColors[color]

        else
            local success, r, g, b = utils.parseHexColor(color)

            if success then
                return {r, g, b}
            end

            return success
        end

    elseif colorType == "table" and (#color == 3 or #color == 4) then
        return color
    end
end

function utils.sameColor(color1, color2)
    if color1 == color2 then
        return true
    end

    if color1 and color2 and color1[1] == color2[1] and color1[2] == color2[2] and color1[3] == color2[3] and color1[4] == color2[4] then
        return true
    end

    return false
end

function utils.callIfFunction(f, ...)
    if type(f) == "function" then
        return f(...)
    end

    return f
end

-- Call function with arguments
-- Use sub values of first argument if it is a table and call function for each of those instead
function utils.callIterateFirstIfTable(f, value, ...)
    -- Make sure this is a table and not a "object"
    if utils.typeof(value) == "table" and #value > 0 then
        for _, subValue in ipairs(value) do
            f(subValue, ...)
        end

    else
        f(value, ...)
    end
end

function utils.typeof(value)
    local typ = type(value)

    if typ == "table" then
        return rawget(value, "_type") or rawget(value, "__type") or typ

    elseif typ == "userdata" and value.type then
        return value:type()

    else
        return typ
    end
end

function utils.isInteger(value)
    if type(value) == "number" then
        return value % 1 == 0
    end

    return false
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

function utils.getPath(data, path, default, createIfMissing)
    local target = data

    for i, key in ipairs(path) do
        local lastKey = i == #path
        local newTarget = target[key]

        if newTarget then
            target = newTarget

        else
            if createIfMissing then
                if not lastKey then
                    target[key] = {}
                    target = target[key]

                else
                    target[key] = default
                    target = default
                end

            else
                return default
            end
        end
    end

    return target
end

utils.countKeys = serialize.countKeys

-- Return the 1 index based tile indices for the coordinates
function utils.pixelsToTiles(x, y)
    return math.floor(x / 8) + 1, math.floor(y / 8) + 1
end

function utils.getRoomAtCoords(x, y, map)
    for i, room in ipairs(map.rooms) do
        if x >= room.x and x <= room.x + room.width and y >= room.y and y <= room.y + room.height then
            return room
        end
    end

    return false
end

function utils.getFillerAtCoords(x, y, map)
    for i, filler in ipairs(map.fillers) do
        if x >= filler.x * 8 and x <= filler.x * 8 + filler.width * 8 and y >= filler.y * 8 and y <= filler.y * 8 + filler.height * 8 then
            return filler
        end
    end

    return false
end

function utils.mod1(n, d)
    local m = n % d

    return m == 0 and d or m
end

function utils.sign(n)
    if n > 0 then
        return 1

    elseif n < 0 then
        return -1

    else
        return 0
    end
end

function utils.logn(base, n)
    return math.log(n) / math.log(base)
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

function utils.getSimpleCoordinateSeed(x, y)
    return math.abs(bit.lshift(x, math.ceil(utils.logn(2, math.abs(y) + 1)))) + math.abs(y)
end

function utils.setSimpleCoordinateSeed(x, y)
    local seed = utils.getSimpleCoordinateSeed(x, y)

    utils.setRandomSeed(seed)
end

function utils.deepcopy(v, copyMetatables)
    if type(v) == "table" then
        local res = {}

        if copyMetatables ~= false then
            setmetatable(res, getmetatable(v))
        end

        for key, value <- v do
            res[key] = utils.deepcopy(value)
        end

        return res

    else
        return v
    end
end

function utils.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)

        t[i], t[j] = t[j], t[i]
    end
end

-- Shallow mode doesn't check table values recursively
function utils.equals(lhs, rhs, shallow)
    if lhs == rhs then
        return true
    end

    local lhsType = type(lhs)
    local rhsType = type(rhs)

    if lhsType ~= rhsType then
        return false
    end

    if lhsType == "table" then
        local equalFunc = shallow and (a, b -> a == b) or utils.equals

        for k, v in pairs(lhs) do
            if not equalFunc(rhs[k], v) then
                return false
            end
        end

        for k, v in pairs(rhs) do
            if not equalFunc(lhs[k], v) then
                return false
            end
        end
    end

    return true
end

function utils.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function utils.round(n, decimals)
    if decimals and decimals > 0 then
        local pow = 10^decimals

        return math.floor(n * pow + 0.5) / pow

    else
        return math.floor(n + 0.5)
    end
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