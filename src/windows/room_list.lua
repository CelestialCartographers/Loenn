local state = require("loaded_state")
local viewportHandler = require("viewport_handler")

local roomList = {}

local roomSelectables = {}
local roomDisplayNames = {}
local selected = nil

function selectCallback(name)
    print("Clicked '" .. name .. "'!")
end

local editModeActiveFlags = {"movable", "scrollbar", "scalable", "border", "title"}
local editModeInactiveFlags = {"scrollbar"}

roomList.x = 0
roomList.y = 0
roomList.width = 300
roomList.height = viewportHandler.viewport.height

roomList.name = "Rooms"

function roomList.init(ui)
    local rooms = state.map and state.map.rooms or {}

    roomSelectables = {}
    roomDisplayNames = {}
    selected = nil

    -- TODO - Sort
    for i, room <- rooms do
        local name = room.name:match("^lvl_(.*)") or room.name

        roomSelectables[name] = {value = i == 1}
        table.insert(roomDisplayNames, name)

        if i == 1 then
            selected = name
        end
    end

    table.sort(roomDisplayNames)
end

function roomList.update(ui)
    -- TODO - Add maploaded event
    if not selected then 
        roomList.init(ui)
    end

    local flags = editModeActiveFlags

    if ui:windowBegin(roomList.name, roomList.x, roomList.y, roomList.width, roomList.height, unpack(flags)) then
        roomList.x, roomList.y = ui:windowGetPosition()
        roomList.width, roomList.height = ui:windowGetSize()
        
        ui:layoutRow("dynamic", 25, 1)
        
        local hasSelection = false

        for i, name <- roomDisplayNames do
            local select = roomSelectables[name]
            if ui:selectable(name, select) then
                -- Reset all others
                for n, s in pairs(roomSelectables) do
                    if n ~= name then
                        s.value = false
                    end
                end

                -- Check if its a new selection or not
                if selected ~= name then
                    selectCallback(name)
                end

                hasSelection = true
                selected = name
            end
        end
        
        if not hasSelection and selected then
            roomSelectables[selected].value = true
        end
    end

	ui:windowEnd()
end

return roomList
