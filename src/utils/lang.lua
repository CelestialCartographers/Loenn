local utils = require("utils")

local lang = {}

local commentPrefix = "^#"
local assignment = "="
local separator = "."

local reservedKeys = table.flip({"_exists", "_path", "_value"})

local nil_lang = {
    _exists = false
}

setmetatable(nil_lang, {
    __tostring = (l -> "%unknown%"),
    __index = function(l, i)
        return nil_lang
    end
})

local fallback_lang = nil_lang

local fallback_lang_mt = {
    __tostring = (l -> l._value),
    __index = function(l, i)
        return nil_lang[i]
    end
}

local lang_mt = {
    __tostring = (l -> l._value),
    __index = function(l, i)
        local target = fallback_lang
        if rawget(l, "_path") then
            for _, part in ipairs(rawget(l, "_path")) do
                target = target[part]
            end
        end
        return target[i]
    end
}

local function deepmetatable(tbl, mt)
    setmetatable(tbl, mt)

    for key, value in pairs(tbl) do
        if not reservedKeys[key] and type(value) == "table" then
          deepmetatable(value, mt)
        end
    end
end

local function getPath(parentPath, part)
    local path = parentPath and table.shallowcopy(parentPath) or {}
    table.insert(path, part)
    return path
end

function lang.parse(str, languageData)
    local res = languageData or {}

    for _, line <- str:gsub("\r\n", "\n"):split("\n", nil, false) do
        if #line:match("^%s*(.*)%s*$") > 0 and not line:find(commentPrefix) then
            local parts = line:split(assignment, nil, false)
            local key, value = parts[1], parts:drop(1):concat(assignment):match("^%s*(.*)%s*$")
            if #key > 0 and #value > 0 then
                local target = res
                for _, part <- key:split(separator, nil, false) do
                    target[part] = rawget(target, part) or setmetatable({_exists = true, _path = getPath(rawget(target, "_path"), part)}, lang_mt)
                    target = target[part]
                end

                target._value = utils.unbackslashify(value)
            end
        end
    end

    return languageData and res or setmetatable(res, lang_mt)
end

function lang.loadFile(filename, languageData, internal)
    local content = utils.readAll(filename, "rb", internal)

    return lang.parse(content, languageData)
end

function lang.setFallback(languageData)
    if fallback_lang ~= nil_lang then
        deepmetatable(fallback_lang, lang_mt)
    end

    fallback_lang = languageData or nil_lang

    if fallback_lang ~= nil_lang then
        deepmetatable(fallback_lang, fallback_lang_mt)
    end
end

return lang