-- Provides the absolute minimum for Steam detection in Lönn

local registry = {}

-- TODO - Support more values?
function registry.parseResult(raw)
    local res = {}
    local lines = string.split(raw, "\n"):filter(line -> #line > 0)

    for i, line <- lines do
        local key, typ, value = line:match("^%s%s%s%s(.+)%s%s%s%s(REG_.+)%s%(%d%d?%)%s%s%s%s(.*)$")

        if typ == "REG_SZ" then
            res[key] = value
        end
    end

    return res
end

-- Does not validate that the key exists or not
function registry.getKey(key)
    local cmd = string.format([[reg.exe query "%s" /z 2>NULL]], key)
    local rawResult = io.popen(cmd):read("*all")

    return registry.parseResult(rawResult)
end

return registry