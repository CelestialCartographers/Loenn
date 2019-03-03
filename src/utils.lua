local function loadImageAbsPath(path)
    local file = io.open(path, "rb")
    local data = love.filesystem.newFileData(file:read("*a"), "image.png")
    file:close()

    return love.graphics.newImage(data)
end

local function twosCompliment(n, power)
    if n >= 2^(power - 1) then
        return n - 2^power

    else
        return n
    end
end

local function stripByteOrderMark(s)
    if s:byte(1) == 0xEF and s:byte(2) == 0xBB and s:byte(3) == 0xBF then
        return s:sub(4, #s)
    end

    return s
end

local function aabbCheck(r1, r2)
    return not (r2.x >= r1.x + r1.width or r2.x + r2.width <= r1.x or r2.y >= r1.y + r1.height or r2.y + r2.height <= r1.y)
end

-- Temp, from https://bitbucket.org/Oddstr13/ac-get-repo/src/8a08af2a87b246e200e83a0e2e7f35a3537d0378/tk-lib-str/lib/str.lua#lines-6 
-- Keeps empty split entries
local function split(s, sSeparator, nMax, bRegexp)
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

return {
    loadImageAbsPath = loadImageAbsPath,
    twosCompliment = twosCompliment,
    stripByteOrderMark = stripByteOrderMark,
    split = split,
    aabbCheck = aabbCheck
}