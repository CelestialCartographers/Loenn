local fileLocations = require("file_locations")

local utils = {}

function utils.twosCompliment(n, power)
    if n >= 2^(power - 1) then
        return n - 2^power

    else
        return n
    end
end

function utils.stripByteOrderMark(s)
    if s:byte(1) == 0xef and s:byte(2) == 0xbb and s:byte(3) == 0xbf then
        return s:sub(4, #s)
    end

    return s
end

function utils.aabbCheck(r1, r2)
    return not (r2.x >= r1.x + r1.width or r2.x + r2.width <= r1.x or r2.y >= r1.y + r1.height or r2.y + r2.height <= r1.y)
end

-- Temp, from https://bitbucket.org/Oddstr13/ac-get-repo/src/8a08af2a87b246e200e83a0e2e7f35a3537d0378/tk-lib-str/lib/str.lua#lines-6 
-- Keeps empty split entries
function utils.split(s, sSeparator, nMax, bRegexp)
-- http://lua-users.org/wiki/SplitJoin
-- "Function: true Python semantics for split"
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)

    local aRecord = {}

    if s:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField=1 nStart=1
        local nFirst,nLast = string.find(s.."",sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = string.sub(s.."",nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = string.find(s.."",sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = string.sub(s.."",nStart)
    end

    return aRecord
end

function utils.getFileHandle(path, mode, internal)
    local internal = internal or fileLocations.useInternal
    
    if internal then
        return love.filesystem.newFile(path, mode:gsub("b", ""))
        
    else
        return io.open(path, mode)
    end
end

function utils.readAll(path, mode, internal)
    local internal = internal or fileLocations.useInternal
    local file = utils.getFileHandle(path, mode, internal)
    local res = internal and file:read() or file:read("*a")

    file:close()

    return res
end

function utils.loadImageAbsPath(path)
    local data = love.filesystem.newFileData(readAll(path, "rb"), "image.png")

    return love.graphics.newImage(data)
end


-- TODO - Get Vex to look at the lambda versions
function utils.humanizeVariableName(name)
    local res = name

    res := gsub("_", " ")
    res := gsub("/", " ")

    res := gsub("(%l)(%u)", function (a, b) return a .. " " .. b end)
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

return utils