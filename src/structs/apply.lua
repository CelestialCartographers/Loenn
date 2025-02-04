local utils = require("utils")
local parallaxStruct = require("structs.parallax")
local effectStruct = require("structs.effect")

local applyStruct = {}

function applyStruct.decode(data)
    local res = {
        _type = "apply"
    }

    for k, v in pairs(data) do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end

    res.children = {}

    for i, child in ipairs(data.__children or {}) do
        if child.__name == "parallax" then
            table.insert(res.children, parallaxStruct.decode(child))

        elseif child.__name == "apply" then
            table.insert(res.children, applyStruct.decode(child))

        -- Anything else with a valid name is a effect
        elseif child.__name then
            table.insert(res.children, effectStruct.decode(child))
        end
    end

    return res
end

function applyStruct.encode(apply)
    local res = {}

    for k, v in pairs(apply) do
        if k:sub(1, 1) ~= "_" and k ~= "children" then
            res[k] = v
        end
    end

    -- Display name in editor
    if apply._name and apply._name ~= "" then
        res._name = apply._name
    end

    res.__children = {}

    for i, backdrop in ipairs(apply.children or {}) do
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