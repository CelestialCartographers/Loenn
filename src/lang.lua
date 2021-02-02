local utils = require("utils")

local lang = {}

local commentPrefix = "^#"
local assignment = "="
local separator = "."

local lang_mt = {
    __tostring = (l -> l._value)
}

function lang.parse(str, languageData)
    local res = languageData or {}

    for _, line <- str:gsub("\r\n", "\n"):split("\n", nil, false) do
        if #line:match("^%s*(.*)%s*$") > 0 and not line:find(commentPrefix) then
            local parts = line:split(assignment, nil, false)
            local key, value = parts[1], parts:drop(1):concat(assignment):match("^%s*(.*)%s*$")
            if #key > 0 and #value > 0 then
                local target = res
                for _, part <- key:split(separator, nil, false) do
                    target[part] = target[part] or setmetatable({}, lang_mt)
                    target = target[part]
                end

                target._value = value
            end
        end
    end

    return languageData and res or setmetatable(res, lang_mt)
end

function lang.loadFile(filename, languageData, internal)
    local content = utils.readAll(filename, "rb", internal)

    return lang.parse(content, languageData)
end

return lang