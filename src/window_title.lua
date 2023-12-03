local sideStruct = require("structs.side")
local meta = require("meta")
local history = require("history")
local utils = require("utils")
local languageRegistry = require("language_registry")

local windowTitleUtils = {}

local previousTitle = ""

function windowTitleUtils.getMapName(state)
    local side = state.side
    local filename = state.filename
    local mapName = sideStruct.getMapName(side)

    if mapName and mapName ~= "" then
        return mapName
    end

    if filename then
        local filenameNoPath = utils.filename(utils.convertToUnixPath(state.filename), "/")
        local filenameNoExt = utils.splitExtension(filenameNoPath)

        return filenameNoExt
    end

    local language = languageRegistry.getLanguage()

    return tostring(language.window_title.new_map)
end

function windowTitleUtils.getWindowTitle(state)
    local side = state.side

    if not side then
        return meta.title
    end

    local mapName = windowTitleUtils.getMapName(state)
    local hasChanges = history.madeChanges
    local changesMark = hasChanges and "● " or ""

    return string.format("%s%s - %s", changesMark, meta.title, mapName)
end

function windowTitleUtils.updateWindowTitle(state)
    local title = windowTitleUtils.getWindowTitle(state)

    if title ~= previousTitle then
        love.window.setTitle(title)

        previousTitle = title
    end
end

return windowTitleUtils