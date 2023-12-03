local windowTitleUtils = require("window_title")
local loadedState = require("loaded_state")
local history = require("history")

local device = {_enabled = true, _type = "device"}

local previousFilename
local previousMadeChanges

-- TODO - Make event driven instead
function device.update()
    local madeChanges = history.madeChanges
    local filename = loadedState.filename

    if filename ~= previousFilename or madeChanges ~= previousMadeChanges then
        windowTitleUtils.updateWindowTitle(loadedState)

        previousFilename = filename
        previousMadeChanges = madeChanges
    end
end

return device