local state = require("loaded_state")

local tool = {}

tool._type = "tool"
tool.name = "Placement"
tool.image = nil

tool.layer = "entities"
tool.validLayers = {
    "entities",
    "triggers",
    "decalsFg",
    "decalsBg"
}

function tool.keypressed(key, scancode, isrepeat)
    local room = state.getSelectedRoom()

    -- Debug layer swapping
    -- TODO - Remove this later
    local index = tonumber(key)

    if index then
        if index >= 1 and index <= #tool.validLayers then
            tool.layer = tool.validLayers[index]

            print("Swapping layer to " .. tool.layer)
        end
    end
end

return tool