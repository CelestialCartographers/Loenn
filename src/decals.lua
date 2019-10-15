local atlases = require("atlases")

local decalUtils = {}

local decalsPrefix = "^decals/"
local decalFrameSuffix = "%d*$"

-- A frame should only be kept if it has no trailing number
-- Or if the trailing number is 0, 00, 000, ... etc
local function keepFrame(name)
    local numberSuffix = name:match(decalFrameSuffix)

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

    for name, sprite in pairs(atlases.gameplay) do
        if name:match(decalsPrefix) then
            if not removeFrames or keepFrame(name) then
                table.insert(res, name)
            end
        end
    end

    return res
end

return decalUtils