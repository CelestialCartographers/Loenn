local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local mods = require("mods")
local loadedState = require("loaded_state")
local stringField = require("ui.forms.fields.string")
local iconUtils = require("ui.utils.icons")
local fileLocations = require("file_locations")

local pathField = {}

pathField.fieldType = "path"

local function openFileDialog(textField, options)
    local relativeToMod = options.relativeToMod
    local allowedExtensions = options.filePickerExtensions or options.allowedExtensions
    local allowFolders = options.allowFolders
    local allowFiles = options.allowFiles
    local useUnixSeparator = options.useUnixSeparator
    local filenameProcessor = options.filenameProcessor

    local useFolderDialog = not allowFiles and allowFolders

    local filter
    local startingPath = fileLocations.getCelesteDir()

    local userOS = utils.getOS()
    local usingWindows = userOS == "Windows"

    if allowedExtensions then
        filter = table.concat(allowedExtensions, ",")
    end

    if relativeToMod ~= false then
        local modPath = mods.getFilenameModPath(loadedState.filename)

        if not modPath then
            return false
        end

        startingPath = modPath
    end

    local function dialogCallback(filename)
        local rawFilename = filename

        if relativeToMod ~= false then
            local modPath = mods.getFilenameModPath(filename)

            if not modPath then
                return false
            end

            filename = string.sub(filename, #modPath + 1)
        end

        if usingWindows and useUnixSeparator ~= false then
            filename = utils.convertToUnixPath(filename)
        end

        if filenameProcessor then
            filename = filenameProcessor(filename, rawFilename)

            if not filename then
                return false
            end
        end

        textField:setText(filename)
    end

    if useFolderDialog then
        utils.openFolderDialog(startingPath, dialogCallback)

    else
        utils.openDialog(startingPath, filter, dialogCallback)
    end
end

function pathField.getElement(name, value, options)
    -- Add extra options and pass it onto string field

    local allowEmpty = options.allowEmpty
    local allowMissingPath = options.allowMissingPath
    local allowFolders = options.allowFolders
    local allowFiles = options.allowFiles
    local allowedExtensions = options.allowedExtensions
    local relativeToMod = options.relativeToMod
    local filenameResolver = options.filenameResolver

    options.validator = function(filename)
        local rawFilename = filename
        local prefix = ""
        local fieldEmpty = filename == nil or #filename == 0

        if fieldEmpty then
            return allowEmpty ~= false
        end

        if relativeToMod ~= false then
            local modPath = mods.commonModContent

            prefix = modPath
            filename = utils.joinpath(modPath, filename)
        end

        if filenameResolver then
            filename = filenameResolver(filename, rawFilename, prefix)
        end

        local attributes = love.filesystem.getInfo(filename) or utils.pathAttributes(filename)

        if not attributes and allowMissingPath == false then
            return false
        end

        local attributeType = attributes and (attributes.type or attributes.mode) or "missing"

        if attributeType == "directory" and not allowFolders then
            return false
        end

        if attributeType == "file" then
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

    local stringElement = stringField.getElement(name, value, options)
    local textfield = stringElement.field

    if textfield.height == -1 then
        textfield:layout()
    end

    local iconMaxSize = textfield.height - textfield.style.padding
    local parentHeight = textfield.height
    local folderIcon, iconSize = iconUtils.getIcon("folder", iconMaxSize)

    if folderIcon then
        local centerOffset = math.floor((parentHeight - iconSize) / 2)
        local folderImage = uiElements.image(folderIcon):with(uiUtils.rightbound(0)):with(uiUtils.at(0, centerOffset))

        folderImage.interactive = 1
        folderImage:hook({
            onClick = function(orig, self)
                orig(self)

                openFileDialog(textfield, options)
            end
        })

        textfield:addChild(folderImage)
    end

    return stringElement
end

return pathField