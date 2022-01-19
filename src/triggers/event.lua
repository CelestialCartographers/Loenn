local enums = require("consts.celeste_enums")

local event = {}

event.name = "eventTrigger"
event.fieldInformation = {
    event = {
        options = enums.event_trigger_events
    }
}
event.placements = {
    name = "event",
    data = {
        event = ""
    }
}

return event