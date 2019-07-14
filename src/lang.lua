local utils = require("utils")

local lang = {}

local commentPrefix = "^#"
local assignment = "="
local separator = "."

local lang_mt = {
    __tostring = (l -> l._value)
}

function lang.parse(str)
    local res = {}

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

    return setmetatable(res, lang_mt)
end

lang.loadFile = (file, internal -> lang.parse(utils.readAll(file, "rb", internal)))

return lang