local state = require("loaded_state")

local device = {_enabled = true}

function device.filedropped(file)
    local filename = file:getFilename()

    state.loadMap(filename)
end

return device