local updater = require("updater")
local github = require("github")

local viewportHandler = require("viewport_handler")

local updaterWindow = {}

local versionSelectables = {}
local versionNames = {}
local selected = nil

local description = ""

local editModeActiveFlags = {"movable", "scrollbar", "scalable", "border", "title"}
local editModeInactiveFlags = {"scrollbar"}

updaterWindow.x = 0
updaterWindow.y = 0
updaterWindow.width = 300
updaterWindow.height = viewportHandler.viewport.height

updaterWindow.name = "Updater"

local function updateDescription(version)
    local success, release = updater.getRelevantRelease(version)

    if success then
        description = release.body
    end
end

function selectCallback(version)
    print("Clicked '" .. version .. "'!")
    updateDescription(version)
end

function updaterWindow.init(ui)
    versionNames = {}
    versionSelectables = {}
    selected = nil
    
    local versions = updater.getAvailableUpdates()

    -- TODO - Sort
    for i, version <- versions do
        versionSelectables[version] = {value = i == 1}
        table.insert(versionNames, version)

        if i == 1 then
            selected = version
            selectCallback(version)
        end
    end

    table.sort(versionNames)
end

function updaterWindow.update(ui)
    if not selected then 
        updaterWindow.init(ui)
    end

    local flags = editModeActiveFlags

    if ui:windowBegin(updaterWindow.name, updaterWindow.x, updaterWindow.y, updaterWindow.width, updaterWindow.height, unpack(flags)) then
        updaterWindow.x, updaterWindow.y = ui:windowGetPosition()
        updaterWindow.width, updaterWindow.height = ui:windowGetSize()
        
        ui:layoutRow("dynamic", 250, 1)
        if ui:groupBegin("Versions", {"scrollbar"}) then
            ui:layoutRow("dynamic", 25, 1)
            
            local hasSelection = false

            for i, name <- versionNames do
                local select = versionSelectables[name]
                if ui:selectable(name, select) then
                    -- Reset all others
                    for n, s in pairs(versionSelectables) do
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
                versionSelectables[selected].value = true
            end

            ui:groupEnd()
        end

        ui:layoutRow("dynamic", 40, 1)
        for i, line <- string.split(description, "\n") do
            ui:label(line, "left")
        end
        
        ui:layoutRow("dynamic", 40, 1)
        if ui:button("Update") then
            if selected then
                updater.update(selected)
            end
        end
    end

	ui:windowEnd()
end

return updaterWindow
