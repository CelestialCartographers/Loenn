local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local history = require("history")
local debugUtils = require("debug_utils")

local menubar = {}

menubar.menubar = {
    {"File", {
        {"New"},
        {"Open", loadedState.openMap},
        {"Recent", {
            {"Here"},
            {"Be"},
            {"Recents"}
        }},
        {},
        {"Save", loadedState.saveCurrentMap},
        {"Save As", loadedState.saveAsCurrentMap},
        {},
        {"Exit", love.event.quit}
    }},
    {"Edit", {
        {"Undo", history.undo},
        {"Redo", history.redo},
        {},
        {"Settings"}
    }},
    {"View", {

    }},
    {"Map", {
        {"Stylegrounds"},
        {"Metadata"}
    }},
    {"Room", {
        {"Add"},
        {"Configure"},
        {},
        {"Delete"}
    }},
    {"Debug", {
        {"Reload", {
            {"Scenes", debugUtils.reloadScenes},
            {"Tools", debugUtils.reloadTools},
            {"Entities", debugUtils.reloadEntities},
            {"Triggers"},
            {"Effects"},
            {"Language Files"}
        }},
        {"Redraw Map", debugUtils.redrawMap},
        {"Test Console", debugUtils.debug}
    }},
    {"Help", {
        {"Check for updates"},
        {"About"}
    }}
}

function menubar.getMenubar()
    return uiElements.topbar(menubar.menubar)
end

return menubar