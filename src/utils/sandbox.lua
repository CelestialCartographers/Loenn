-- Based on microbenchmark by asiekierka in OpenComputers

local jit = require("jit")

local utils = {}

local hookInterval
local ipsCount

local function calcIpsCount(hookInterval)
    -- Disable JIT optimizations on the current function.
    -- Required because LuaJIT would otherwise optimize
    -- the "infinite" loop and make it actually infinite.
    jit.off(true)

    local bogomipsDivider = 0.05
    local bogomipsDeadline = love.timer.getTime() + bogomipsDivider
    local ipsCount = 0
    local bogomipsBusy = true

    local function calcBogoMips()
        ipsCount = ipsCount + hookInterval
        if love.timer.getTime() > bogomipsDeadline then
            bogomipsBusy = false
        end
    end

    -- The following is a bit of nonsensical-seeming code attempting
    -- to cover Lua's VM sufficiently for the IPS calculation.
    local bogomipsTmpA = {{["b"]=3, ["d"]=9}}
    local function c(k)
        if k <= 2 then
            bogomipsTmpA[1].d = k / 2.0
        end
    end

    debug.sethook(calcBogoMips, "", hookInterval)
    while bogomipsBusy do
        local st = ""
        for k=2,4 do
            st = st .. "a" .. k
            c(k)
            if k >= 3 then
                bogomipsTmpA[1].b = bogomipsTmpA[1].b * (k ^ k)
            end
        end
    end

    debug.sethook()

    return ipsCount / bogomipsDivider
end

function utils.calcIpsAndHookInterval()
    local _hookInterval = 1000
    local _ipsCount = calcIpsCount(_hookInterval)

    -- Since our IPS might still be too generous (hookInterval needs to run at most
    -- every 0.05 seconds), we divide it further by 10 relative to that.
    _hookInterval = (_ipsCount * 0.005)

    if _hookInterval < 1000 then _hookInterval = 1000 end

    ipsCount = _ipsCount
    hookInterval = _hookInterval

    return _ipsCount, _hookInterval
end

local tooLongWithoutYielding = setmetatable({},  { __tostring = function() return "too long without yielding" end})

-- Timeout code adapted from OpenCompuers
function utils.pcallWithTimeout(f, timeout, ...)
    if not timeout then
        return pcall(f, ...)
    end

    -- Disable JIT optimization so that debug hooks work
    jit.off(f, true)

    -- Emergency initialization if needed
    if not hookInterval then
        utils.calcIpsAndHookInterval()
    end

    local deadline = math.huge
    local function checkDeadline()
        if love.timer.getTime() > deadline then
            error(tooLongWithoutYielding)
        end
    end

    deadline = love.timer.getTime() + timeout

    debug.sethook(checkDeadline, "", hookInterval)
    -- Very naïve but better than nothing
    local res = {pcall(f, ...)}
    debug.sethook()

    return unpack(res)
end

return utils