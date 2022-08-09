local utils = require("utils")
local mods = require("mods")
local loadedState = require("loaded_state")
local stringField = require("ui.forms.fields.string")

local pathField = {}

pathField.fieldType = "path"

function pathField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local allowEmpty = options.allowEmpty
    local allowMissingPath = options.allowMissingPath
    local allowFolders = options.allowFolders
    local allowFiles = options.allowFiles
    local allowedExtensions = options.allowedExtensions
    local relativeToMod = options.relativeToMod

    options.validator = function(filename)
        local fieldEmpty = filename == nil or #filename == 0

        if fieldEmpty then
            return allowEmpty ~= false
        end

        if relativeToMod ~= false then
            local modPath = mods.getFilenameModPath(loadedState.filename)

            if not modPath then
                return false
            end

            filename = utils.joinpath(modPath, filename)
        end

        local attributes = utils.pathAttributes(filename)

        if not attributes and allowMissingPath ~= false then
            return false
        end

        local attributeMode = attributes.mode or "missing"

        if attributeMode == "directory" and not allowFolders then
            return false
        end

        if attributeMode == "file" then
            local fileExtension = utils.fileExtension(filename)

            if allowFiles == false then
                return false
            end

            if allowedExtensions and not utils.contains(fileExtension, allowedExtensions) then
                return false
            end
        end

        -- TODO - Custom validator at this point?

        return true
    end

    return stringField.getElement(name, value, options)
end

return pathField