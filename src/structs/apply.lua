local utils = require("utils")
local parallaxStruct = require("structs/parallax")
local effectStruct = require("structs/effect")

local applyStruct = {}

function applyStruct.decode(data)
    res = {
        _type = "apply",
        _raw = data
    }

    for k, v <- data do
        if k ~= "__children" then
            res[k] = v
        end
    end

    res.__children = {}

    for i, child <- data.__children or {} do
        if child.__name == "parallax" then
            table.insert(res.__children, parallaxStruct.decode(child))

        elseif child.__name == "apply" then
            table.insert(res.__children, applyStruct.decode(child))

        -- Anything else with a valid name is a effect
        elseif child.__name then
            table.insert(res.__children, effectStruct.decode(child))
        end
    end

    return res
end

function applyStruct.encode(apply)
    local res = {}

    for k, v <- apply do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end

    res.__children = {}

    for i, backdrop <- apply.__children or {} do
        local typ = utils.typeof(backdrop)

        if typ == "parallax" then
            table.insert(res.__children, parallaxStruct.encode(backdrop))

        elseif typ == "apply" then
            table.insert(res.__children, applyStruct.encode(backdrop))

        elseif typ == "effect" then
            table.insert(res.__children, effectStruct.encode(backdrop))
        end
    end

    res.__name = "apply"

    return res
end

return applyStruct