local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local mods = require("mods")
local loadedState = require("loaded_state")
local atlases = require("atlases")
local stringField = require("ui.forms.fields.string")
local iconUtils = require("ui.utils.icons")
local fileLocations = require("file_locations")

local pathField = {}

pathField.fieldType = "path"

local function getDialogCallback(textField, options)
    return function(filename)
        -- User closed dialog or hit cancel
        if not filename then
            return
        end

        local rawFilename = filename

        local useUnixSeparator = options.useUnixSeparator
        local filenameProcessor = options.filenameProcessor
        local relativeToMod = options.relativeToMod

        local userOS = utils.getOS()
        local usingWindows = userOS == "Windows"

        if relativeToMod ~= false then
            local modPath = mods.getFilenameModPath(filename)

            if not modPath then
                return false
            end

            filename = string.sub(filename, #modPath + 2)
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
        textField.index = #filename
    end
end

local function openFileDialog(textField, options)
    local relativeToMod = options.relativeToMod
    local allowedExtensions = options.filePickerExtensions or options.allowedExtensions
    local allowFolders = options.allowFolders
    local allowFiles = options.allowFiles

    local useFolderDialog = not allowFiles and allowFolders

    local filter
    local startingPath = fileLocations.getCelesteDir()

    if allowedExtensions then
        filter = table.concat(allowedExtensions, ",")
    end

    if relativeToMod ~= false then
        local modPath = mods.getFilenameModPath(loadedState.filename)

        -- Use current mod root if posible, otherwise use Celeste root
        startingPath = modPath or startingPath
    end

    if useFolderDialog then
        utils.openFolderDialog(startingPath, getDialogCallback(textField, options))

    else
        utils.openDialog(startingPath, filter, getDialogCallback(textField, options))
    end
end

local function fileDropped(orig, self, file)
    local cursorX, cursorY = love.mouse.getPosition()
    local hoveredElement = ui.root:getChildAt(cursorX, cursorY)
    local target = hoveredElement
    local hovered = false

    while target and not hovered do
        hovered = target == self
        target = target.parent
    end

    if hovered then
        local fieldElement = self._fieldElement
        local filename = file:getFilename()

        getDialogCallback(self, fieldElement._options)(filename)

        return true
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
    local celesteAtlas = options.celesteAtlas
    local filenameResolver = options.filenameResolver
    local earlyValidator = options.earlyValidator
    local lateValdiator = options.lateValdiator

    options.validator = function(filename)
        local rawFilename = filename
        local prefix = ""
        local fieldEmpty = filename == nil or #filename == 0

        -- Early vaidator before all checks and filename transforms
        if earlyValidator then
            local result = earlyValidator(filename)

            if result ~= nil then
                return result
            end
        end

        if fieldEmpty then
            return allowEmpty ~= false
        end

        if celesteAtlas then
            local atlas = atlases[celesteAtlas]

            if atlas and atlas[filename] then
                return true
            end
        end

        if relativeToMod ~= false then
            local modPath = mods.commonModContent

            prefix = modPath
            filename = utils.joinpath(modPath, filename)

            -- Has to use unix paths for Love2d to detect the file
            filename = utils.convertToUnixPath(filename)
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

        -- Late vaidator after all checks and filename transforms
        if lateValdiator then
            local result = lateValdiator(filename)

            if result ~= nil then
                return result
            end
        end

        return true
    end

    local stringElement = stringField.getElement(name, value, options)
    local textfield = stringElement.field

    stringElement._options = options
    textfield._fieldElement = stringElement

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

    textfield:hook({
        filedropped = fileDropped
    })

    return stringElement
end

return pathField