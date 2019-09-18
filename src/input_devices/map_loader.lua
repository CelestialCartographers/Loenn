local state = require("loaded_state")

local device = {_enabled = true, _type = "device"}

function device.filedropped(file)
    local filename = file:getFilename()

    state.loadFile(filename)
end

return device