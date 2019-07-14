local serialize = {}

local keywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["goto"] = true, ["if"] = true, ["in"] = true,
    ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true,
    ["until"] = true, ["while"] = true
}

local variablePattern = "^[%a_][%w_]*$"

function serialize.countKeys(t)
    local numerical = 0
    local total = 0

    for k, v in pairs(t) do
        if type(k) == "number" then
            numerical = numerical + 1
        end

        total = total + 1
    end

    return total, numerical
end

function serialize.numericalLength(t)
    local index = 0

    while t[index + 1] do
        index = index + 1
    end

    return index
end

function serialize.serialize(t, pretty, seen, depth, success)
    local res = {}

    seen = seen or {}
    depth = depth or 0
    pretty = not not pretty
    success = success == nil or success

    local keyCount, numIndices = serialize.countKeys(t)
    local length = serialize.numericalLength(t)

    local count = 0

    for k, v in pairs(t) do
        count = count + 1

        local ktyp = type(k)
        local vtyp = type(v)

        local key = k
        local value = v

        if keywords[k] or not string.match(k, variablePattern)then
            if ktyp == "string" then
                key = "[" .. string.format("%q", k) .. "]"

            elseif ktyp == "number" then
                if numIndices > length then
                    key = "[" .. tonumber(k) .. "]"

                else
                    key = ""
                end
            end
        end

        if vtyp == "nil" then
            value = "nil"

        elseif vtyp == "boolean" then
            value = value and "true" or "false"

        elseif vtyp == "number" then
            if value ~= value then
                value = "0 / 0"

            elseif value == math.huge then
                value = "math.huge"

            elseif value == -math.huge then
                value = "-math.huge"

            else
                value = tostring(value)
            end

        elseif vtyp == "table" then
            if not seen[value] then
                seen[value] = true
                success, value = serialize.serialize(value, pretty, seen, depth + 1, success)

            else
                success = false
                value = tostring(value)
            end

        elseif vtyp == "string" then
            value = string.format("%q", value):gsub("\\\n","\\n")

        else
            value = tostring(value)
            success = false
        end

        local padding = pretty and string.rep("    ", depth + 1) or ""
        local keyAssign = #key > 0 and key .. " = " or ""
        local comma = count == keyCount and "" or ","

        table.insert(res, padding .. keyAssign .. value .. comma)
    end

    local closingPadding = pretty and string.rep("    ", depth) or ""
    local newline = pretty and "\n" or ""
    local lineSep = pretty and "\n" or " "

    return success, "{" .. newline .. table.concat(res, lineSep) .. newline .. closingPadding .. "}"
end

function serialize.unserialize(s)
    local func = assert(loadstring("return " .. s))

    return func()
end

return serialize