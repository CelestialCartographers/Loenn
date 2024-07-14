local logging = require("logging")
local mods = require("mods")

local modificationWarner = {}

modificationWarner._MT = {}

function modificationWarner._MT:__newindex(key, value)
    -- Check for direct modifications, not intended helper functions
    local currentModName = mods.getCurrentModName(3)

    if currentModName then
        local warnerFilename = self._warnerFilename
        local info = debug.getinfo(2)
        local targetFilename = info.source
        local message = string.format("'%s' in '%s' was modified by '%s' (%s)", key, warnerFilename, currentModName, targetFilename)

        logging.warning(message)
    end

    rawset(self, key, value)
end

function modificationWarner.addModificationWarner(targetTable)
    if getmetatable(targetTable) then
        logging.warning("Modfification warnings can not be added to tables that already have metatables")

        return
    end

    local info = debug.getinfo(2)
    local source = info.source

    targetTable._warnerFilename = source

    return setmetatable(targetTable, modificationWarner._MT)
end

return modificationWarner