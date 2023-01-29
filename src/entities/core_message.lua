-- Only add placement for the Everest core message
-- Everest version allows custom dialog and some extra features

local coreMessage = {}

coreMessage.name = "coreMessage"
coreMessage.depth = 0
coreMessage.texture = "@Internal@/core_message"

local everestCoreMessage = {}

everestCoreMessage.name = "everest/coreMessage"
everestCoreMessage.associatedMods = {"Everest"}
everestCoreMessage.depth = 0
everestCoreMessage.texture = "@Internal@/core_message"
everestCoreMessage.fieldInformation = {
    line = {
        fieldType = "integer",
    }
}

everestCoreMessage.placements = {
    name = "core_message",
    data = {
        line = 0,
        dialog = "app_ending",
        outline = false
    }
}

return {
    coreMessage,
    everestCoreMessage
}