local hasTableNew, tableNew = pcall(require, "table.new")

local dataUtils = {}

function dataUtils.newTable()
    return {}
end

-- Replace with luajit extension if it is available
if hasTableNew then
    dataUtils.newTable = tableNew
end

return dataUtils