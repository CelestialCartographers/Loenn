-- TODO - Allow passing around settings table instead of using args?
-- Makes it easier to have "profiles" for serializing

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
local ignoredKeysPattern = "^__"

-- Defaults for nil values
-- Options for output style, any string values assumes it will still produce valid Lua
serialize.pretty = true
serialize.sortKeys = true
serialize.useMultilineComments = false
serialize.useMetaKeys = true
serialize.alwaysUseBracketsOnNumericalGaps = true

serialize.indent = "    "
serialize.equals = " = "
serialize.inlineValueSeparator = ", "
serialize.commentSingleline = "-- "
serialize.commentMultilineStart = "--[["
serialize.commentMultilineStop = "--]]"

local function isMetaKey(key, useMetaKeys)
    return useMetaKeys and type(key) == "string" and key:match(ignoredKeysPattern)
end

function serialize.countKeys(t, useMetaKeys)
    local numerical = 0
    local total = 0

    for k, v in pairs(t) do
        local keyType = type(k)

        if keyType == "number" then
            numerical = numerical + 1
            total = total + 1

        elseif keyType == "string" then
            if not isMetaKey(k, useMetaKeys) then
                total = total + 1
            end

        else
            total = total + 1
        end
    end

    return total, numerical
end

function serialize.numericalLength(t)
    local index = 0

    while rawget(t, index + 1) ~= nil do
        index = index + 1
    end

    return index
end

function serialize.formatComment(comment, padding, useMultilineComments)
    local lines = {}
    local commentLines = {}

    useMultilineComments = (useMultilineComments == nil and serialize.useMultilineComments) or useMultilineComments

    for line in comment:gsub("\r\n", "\n"):gmatch("[^\n]+") do
        table.insert(commentLines, line)
    end

    if #commentLines == 1 then
        return padding .. "-- " .. commentLines[1]

    else
        local commentPrefix = useMultilineComments and "" or serialize.commentSingleline

        if useMultilineComments then
            table.insert(lines, padding .. serialize.commentMultilineStart)
        end

        for _, line in ipairs(commentLines) do
            table.insert(lines, padding .. commentPrefix .. line)
        end

        if useMultilineComments then
            table.insert(lines, padding .. serialize.commentMultilineStop)
        end

        return table.concat(lines, "\n")
    end
end

function serialize.getEntries(entries, sortKeys)
    local entryValues = {}

    if sortKeys then
        local entryKeys = {}

        for k, v in pairs(entries) do
            table.insert(entryKeys, k)
        end

        table.sort(entryKeys)

        for _, k in ipairs(entryKeys) do
            table.insert(entryValues, entries[k])
        end

    else
        for k, v in pairs(entries) do
            table.insert(entryValues, v)
        end
    end

    return entryValues
end

-- Metakeys are extra information keys for output, prefixed with __
-- These keys are not serialized when using `useMetaKeys`
-- Metakeys are as follows:
-- * __comments Adds comments to keys in the table
-- * __comment Adds a comment for it self, overwrites __comments of parent
function serialize.serialize(t, pretty, sortKeys, useMetaKeys, seen, depth, success)
    local entries = {}
    local noKeyEntries = {}
    local bracketedNumerEntries = {}

    seen = seen or {}
    depth = depth or 0
    pretty = pretty == nil and serialize.pretty or pretty
    sortKeys = sortKeys == nil and serialize.sortKeys or sortKeys
    useMetaKeys = useMetaKeys == nil and serialize.useMetaKeys or useMetaKeys
    success = success == nil or success

    local keyCount, numIndices = serialize.countKeys(t, useMetaKeys)
    local length = serialize.numericalLength(t)

    local keyComments = useMetaKeys and t and t.__comments or {}

    local count = 0

    for k, v in pairs(t) do
        local ignoredKey = isMetaKey(k, useMetaKeys)

        if not ignoredKey then
            local keyType = type(k)
            local valueType = type(v)

            local key = k
            local value = v

            count = count + 1

            if keywords[k] or not string.match(k, variablePattern) then
                if keyType == "string" then
                    key = "[" .. string.format("%q", k) .. "]"

                elseif keyType == "number" then
                    local useBrackets = serialize.alwaysUseBracketsOnNumericalGaps and numIndices > length or k > length

                    if useBrackets then
                        key = "[" .. tonumber(k) .. "]"

                    else
                        key = ""
                    end
                end
            end

            if valueType == "nil" then
                value = "nil"

            elseif valueType == "boolean" then
                value = value and "true" or "false"

            elseif valueType == "number" then
                if value ~= value then
                    value = "0 / 0"

                elseif value == math.huge then
                    value = "math.huge"

                elseif value == -math.huge then
                    value = "-math.huge"

                else
                    value = tostring(value)
                end

            elseif valueType == "table" then
                if not seen[value] then
                    seen[value] = true
                    success, value = serialize.serialize(value, pretty, sortKeys, useMetaKeys, seen, depth + 1, success)

                else
                    value = tostring(value)
                    success = false
                end

            elseif valueType == "string" then
                value = string.format("%q", value):gsub("\\\n","\\n")

            else
                value = tostring(value)
                success = false
            end

            local lines = {}

            local padding = pretty and string.rep(serialize.indent, depth + 1) or ""
            local keyAssign = #key > 0 and key .. serialize.equals or ""
            local comment = valueType == "table" and v.__comment or keyComments[k]

            if pretty and useMetaKeys and comment then
                table.insert(lines, serialize.formatComment(comment, padding))
            end

            table.insert(lines, padding .. keyAssign .. value)

            -- Put entry in the correct category for sorting later
            if key ~= "" then
                if sortKeys and keyType == "number" then
                    bracketedNumerEntries[k] = table.concat(lines, "\n")

                else
                    entries[key] = table.concat(lines, "\n")
                end

            else
                noKeyEntries[k] = table.concat(lines, "\n")
            end
        end
    end

    local closingPadding = pretty and string.rep(serialize.indent, depth) or ""
    local newline = pretty and "\n" or ""
    local lineSep = pretty and ",\n" or serialize.inlineValueSeparator

    local entryValues = serialize.getEntries(entries, sortKeys)
    local bracketedNumberValues = serialize.getEntries(bracketedNumerEntries, sortKeys)

    local noKeyConent = table.concat(noKeyEntries, lineSep)
    local bracketNumberContent = table.concat(bracketedNumberValues, lineSep)
    local keyValueContent = table.concat(entryValues, lineSep)

    local noKeyToBracketedSep = #noKeyConent > 0 and lineSep or ""
    local bracketToKeySep = #bracketNumberContent > 0 and lineSep or ""

    return success, "{" .. newline .. noKeyConent .. noKeyToBracketedSep .. bracketNumberContent .. bracketToKeySep .. keyValueContent .. newline .. closingPadding .. "}"
end

function serialize.unserialize(s)
    local func = assert(loadstring("return " .. s))

    return func()
end

return serialize