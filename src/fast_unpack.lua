local fast_unpack = {}
local unpack_mt = {}

function unpack_mt.__call(u, tbl)
    local len = #tbl

    if not u[len] then
        local values = {}

        for i = 1, len do
            values[i] = string.format("t[%d]", i)
        end

        u[len] = assert(load(string.format("return function(t) return %s end", table.concat(values, ","))))()
    end

    return u[len](tbl)
end

setmetatable(fast_unpack, unpack_mt)

unpack_orig = unpack
unpack = fast_unpack
