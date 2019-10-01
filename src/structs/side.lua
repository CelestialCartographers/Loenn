local utils = require("utils")
local mapStruct = require("structs.map")

local sideStruct = {}

local decoderBlacklist = {
    Filler = true,
    Style = true,
    levels = true
}

local encoderBlacklist = {
    map = true,
    _raw = true,
    _type = true
}

local function tableify(data, t)
    t = t or {}

    local name = data.__name
    local children = data.__children or {}

    t[name] = {}

    for k, v in pairs(data) do
        if k:sub(1, 1) ~= "_" then
            t[name][k] = v
        end
    end

    for i, child in ipairs(children) do
        tableify(child, t)
    end

    return t
end

local function binfileify(name, data, topLevel)
    local res = {
        __name = name,
        __children = {}
    }

    for k, v in pairs(data) do
        if type(v) == "table" then
            table.insert(res.__children, binfileify(k, v))

        else
            res[k] = v
        end
    end

    if #res.__children == 0 then
        res.__children = nil
    end

    return res
end

function sideStruct.decode(data)
    local side = {
        _type = "map",
        _raw = data
    }

    for i, v in ipairs(data.__children or {}) do
        local name = v.__name

        if not decoderBlacklist[name] then
            tableify(v, side)
        end
    end

    side.map = mapStruct.decode(data)

    return side
end

function sideStruct.encode(side)
    local res = mapStruct.encode(side.map)

    for k, v in pairs(side) do
        if not encoderBlacklist[k] then
            table.insert(res.__children, binfileify(k, v))
        end
    end

    return res
end

return sideStruct