local utils = require("utils")
local parallaxStruct = require("structs.parallax")
local effectStruct = require("structs.effect")
local applyStruct = require("structs.apply")

local styleStruct = {}

-- Only returns children decoded
function styleStruct.decode(data)
    res = {}

    for i, child <- data.__children or {} do
        if child.__name == "parallax" then
            table.insert(res, parallaxStruct.decode(child))

        elseif child.__name == "apply" then
            table.insert(res, applyStruct.decode(child))

        -- Anything else with a valid name is a effect
        elseif child.__name then
            table.insert(res, effectStruct.decode(child))
        end
    end

    return res
end

-- Only returns children encoded
function styleStruct.encode(style)
    local res = {}

    for i, backdrop <- style do
        local typ = utils.typeof(backdrop)
        
        if typ == "parallax" then
            table.insert(res, parallaxStruct.encode(backdrop))

        elseif typ == "apply" then
            table.insert(res, applyStruct.encode(backdrop))

        elseif typ == "effect" then
            table.insert(res, effectStruct.encode(backdrop))
        end
    end

    return res
end

return styleStruct