local atlases = require("atlases")

local decalUtils = {}

local decalsPrefix = "^decals/"
local decalFrameSuffix = "%d*$"

local function keepFrame(name)
    local numberSuffix = name:match(decalFrameSuffix)

    if #numberSuffix == 0 then
        return true
    end

    for i = 1, #numberSuffix do
        if numberSuffix:sub(i, i) ~= "0" then
            return false
        end
    end

    return true
end

function decalUtils.getDecalNames(removeFrames)
    removeFrames = removeFrames == nil or removeFrames

    local res = {}

    for name, sprite <- atlases.gameplay do
        if name:match(decalsPrefix) then
            if not removeFrames or keepFrame(name) then
                table.insert(res, name)
            end
        end
    end

    return res
end

return decalUtils