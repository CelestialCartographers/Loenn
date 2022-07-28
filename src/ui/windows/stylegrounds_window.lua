local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local loadedState = require("loaded_state")
local languageRegistry = require("language_registry")
local utils = require("utils")
local form = require("ui.forms.form")
local configs = require("configs")
local enums = require("consts.celeste_enums")
local stylegroundEditor = require("ui.styleground_editor")
local listWidgets = require("ui.widgets.lists")
local widgetUtils = require("ui.widgets.utils")
local formHelper = require("ui.forms.form")
local parallax = require("parallax")
local effects = require("effects")
local formUtils = require("ui.utils.forms")
local atlases = require("atlases")

local stylegroundWindow = {}

local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

local stylegroundWindowGroup = uiElements.group({}):with({

})

-- TODO - Layouting variables that should be more dyanmic
local PREVIEW_MAX_WIDTH = 320 * 3
local PREVIEW_MAX_HEIGHT = 180 * 3
local WINDOW_STATIC_HEIGHT = 640

-- List icon to indicate foreground vs background
local function listItemCheckbox(text, value)
    local checkbox = uiElements.checkbox(text, value)

    checkbox.checkbox.style.disabledBG = {0.0, 0.0, 0.0, 0.0}
    checkbox.checkbox.style.disabledFG = {0.0, 0.0, 0.0, 0.0}
    checkbox.checkbox.style.disabledBorder = {0.0, 0.0, 0.0, 0.0}

    checkbox.enabled = false

    return checkbox
end

local function getStylegroundItems(targets, fg, items, parent)
    local language = languageRegistry.getLanguage()

    items = items or {}

    for _, style in ipairs(targets) do
        local styleType = utils.typeof(style)

        if styleType == "parallax" then
            local displayName = parallax.displayName(language, style)
            local listItem = listItemCheckbox(displayName, fg)

            table.insert(items, {
                text = listItem,
                data = {
                    style = style,
                    parentStyle = parent,
                    foreground = fg
                }
            })

        elseif styleType == "effect" then
            local displayName = effects.displayName(language, style)
            local listItem = listItemCheckbox(displayName, fg)

            table.insert(items, {
                text = listItem,
                data = {
                    style = style,
                    parentStyle = parent,
                    foreground = fg
                }
            })

        elseif styleType == "apply" then
            -- TODO - Better visuals later
            if style.children then
                getStylegroundItems(style.children, fg, items, style)
            end
        end
    end

    return items
end

local function getHandler(style)
    local styleType = utils.typeof(style)

    if styleType == "parallax" then
        return parallax

    elseif styleType == "effect" then
        return effects
    end
end

local function getOptions(style)
    local handler = getHandler(style)
    local prepareOptions = {
        namePath = {"attribute"},
        tooltipPath = {"description"}
    }
    local dummyData, fieldInformation, fieldOrder = formUtils.prepareFormData(handler, style, prepareOptions, {style})
    local options = {
        fields = fieldInformation,
        fieldOrder = fieldOrder
    }

    return options, dummyData
end

local function getBestScale(width, height, maxWidth, maxHeight)
    local scaleX = 1
    local scaleY = 1

    while width >= maxWidth do
        width /= 2
        scaleX /= 2
    end

    while height >= maxHeight do
        height /= 2
        scaleY /= 2
    end

    return math.min(scaleX, scaleY)
end

local function getStylegroundPreview(interactionData)
    local language = languageRegistry.getLanguage()
    local formData = interactionData.formData
    local listTarget = interactionData.listTarget
    local style = listTarget and listTarget.style or {}
    local styleType = utils.typeof(style)

    -- Not ready yet
    if not formData then
        return
    end

    if styleType == "parallax" then
        local texture = formData.texture
        local sprite = atlases.getResource(texture)

        if sprite then
            local color = formData.color
            local imageElement = uiElements.image(sprite.image, sprite.quad, sprite.layer)

            if color then
                local success, r, g, b, a = utils.parseHexColor(color)

                if success then
                    imageElement.style.color = {r, g, b, a}
                end
            end

            -- Update image size
            imageElement:layout()

            local imageWidth, imageHeight = imageElement.width / imageElement.scaleX, imageElement.height / imageElement.scaleY
            local bestScale = getBestScale(imageWidth, imageHeight, PREVIEW_MAX_WIDTH, PREVIEW_MAX_HEIGHT)

            imageElement.scaleX = bestScale
            imageElement.scaleY = bestScale

            return imageElement

        else
            return uiElements.label(tostring(language.ui.styleground_window.preview.unknown_texture))
        end
    end

    return uiElements.label(formData.texture or formData._name or tostring(language.ui.styleground_window.preview.no_preview))
end

-- TODO - Improve in the future
-- We can most likely reuse a previous image or label, but this works for now
local function updateStylegroundPreview(interactionData)
    local previewContainer = interactionData.stylegroundPreviewGroup
    local newPreview = getStylegroundPreview(interactionData)

    if previewContainer.children[1] then
        previewContainer:removeChild(previewContainer.children[1])
    end

    if newPreview then
        previewContainer:addChild(newPreview)
    end
end

local function prepareFormData(interactionData)
    local listTarget = interactionData.listTarget
    local formData = {}

    if not listTarget then
        return formData
    end

    local style = listTarget.style or {}
    local parentStyle = listTarget.parentStyle or {}

    -- Copy in parent style, clear name and type
    for k, v in pairs(parentStyle) do
        formData[k] = v
    end

    formData.__name = nil
    formData._type = nil

    -- Copy style
    for k, v in pairs(style) do
        formData[k] = v
    end

    -- Filter out apply children
    if type(formData.children) == "table" then
        formData.children = nil
    end

    -- Add any missing default values
    local handler = getHandler(style)
    local defaultData = handler.defaultData(style) or {}

    for k, v in pairs(defaultData) do
        if formData[k] == nil then
            formData[k] = v
        end
    end

    return formData
end

local function applyFormChanges(interactionData, newData)
    -- TODO - Handle parent better, ignore for now

    local listTarget = interactionData
    local style = interactionData.listTarget.style

    for k, v in pairs(newData) do
        style[k] = v
    end
end

local function addNewStyle(interactionData)
    print("TODO - Add", utils.serialize(interactionData.addNewMethod))
end

local function removeStyle(interactionData)
    print("TODO - Remove")
end

local function moveStyleUp(interactionData)
    print("TODO - Move up")
end

local function moveStyleDown(interactionData)
    print("TODO - Move down")
end

local function changeStyleForeground(interactionData)
    local listTarget = interactionData.listTarget
    local foreground = listTarget.foreground
    print("TODO - Change foreground", foreground)
end

local function getNewDropdownOptions()
    local language = languageRegistry.getLanguage()
    local knownEffects = effects.registeredEffects

    local options = {
        {
            text = tostring(language.ui.styleground_window.new_options.based_on_current),
            data = {
                method = "basedOnCurrent"
            }
        },
        {
            text = tostring(language.ui.styleground_window.new_options.parallax),
            data = {
                method = "parallax"
            }
        },
    }

    for name, handler in pairs(knownEffects) do
        local fakeEffect = {_name = name}
        local displayName = effects.displayName(language, fakeEffect)

        table.insert(options, {
            text = displayName,
            data = {
                method = "effect",
                name = name
            }
        })
    end

    return options
end

local function getStylegroundFormButtons(interactionData, formFields, formOptions)
    local listTarget = interactionData.listTarget

    if not listTarget then
        return
    end

    local language = languageRegistry.getLanguage()
    local style = listTarget.style
    local foreground = listTarget.foreground

    local handler = getHandler(style)

    local canForeground = handler.canForeground(style)
    local canBackground = handler.canBackground(style)
    local canChangeForeground = canForeground and canBackground

    local moveToForegroundText = tostring(language.ui.styleground_window.form.move_to_foreground)
    local moveToBackgroundText = tostring(language.ui.styleground_window.form.move_to_background)
    local changeForegroundButton = {
        text = foreground and moveToBackgroundText or moveToForegroundText,
        callback = function(formFields)
            changeStyleForeground(interactionData)
        end
    }

    local buttons = {
        {
            text = tostring(language.ui.styleground_window.form.new),
            callback = function(formFields)
                addNewStyle(interactionData)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.remove),
            callback = function(formFields)
                removeStyle(interactionData)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.update),
            formMustBeValid = true,
            callback = function(formFields)
                applyFormChanges(interactionData, form.getFormData(formFields))
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.move_up),
            callback = function(formFields)
                moveStyleUp(interactionData)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.move_down),
            callback = function(formFields)
                moveStyleDown(interactionData)
            end
        },
    }

    if canChangeForeground then
        table.insert(buttons, changeForegroundButton)
    end

    local buttonRow = formHelper.getFormButtonRow(buttons, formFields, formOptions)
    local newDropdownItems = getNewDropdownOptions()
    local newDropdown = uiElements.dropdown(newDropdownItems, function(item, data)
        interactionData.addNewMethod = data
    end)

    interactionData.addNewMethod = newDropdownItems[1].data

    table.insert(buttonRow.children, 1, newDropdown)

    return buttonRow
end

local function getStylegroundForm(interactionData)
    local formData = prepareFormData(interactionData)
    local formOptions, dummyData = getOptions(formData)

    -- TODO - Add to config file?
    formOptions.columns = 8
    formOptions.formFieldChanged = function(formFields, field)
        local newData = form.getFormData(formFields)

        interactionData.formData = newData

        updateStylegroundPreview(interactionData)
    end

    local formBody, formFields = formHelper.getFormBody(dummyData, formOptions, buttons)
    local buttonRow = getStylegroundFormButtons(interactionData, formFields, formOptions)

    return uiElements.column({formBody, buttonRow})
end

local function updateStylegroundForm(interactionData)
    local formContainer = interactionData.formContainerGroup
    local newForm = getStylegroundForm(interactionData)

    if formContainer.children[1] then
        formContainer:removeChild(formContainer.children[1])
    end

    formContainer:addChild(newForm)
end

local function getStylegroundList(map, interactionData)
    local items = {}
    local listItems = {}

    getStylegroundItems(map.stylesFg or {}, true, items)
    getStylegroundItems(map.stylesBg or {}, false, items)

    for i, s in ipairs(items) do
        local item = uiElements.listItem({
            text = s
        })

        listItems[i] = item
    end

    local column, list = listWidgets.getList(function(element, listItem)
        interactionData.listTarget = listItem
        interactionData.formData = prepareFormData(interactionData)

        updateStylegroundForm(interactionData)
        updateStylegroundPreview(interactionData)
    end, items, {initialItem = 1})

    return column, list
end

local function getWindowContent(map)
    local interactionData = {}

    local stylegroundFormGroup = uiElements.group({}):with(uiUtils.bottombound)
    local stylegroundListColumn, stylegroundList = getStylegroundList(map, interactionData)
    local stylegroundPreview = uiElements.group({
        getStylegroundPreview(interactionData)
    })
    local stylegroundForm = getStylegroundForm(interactionData)

    stylegroundFormGroup:addChild(stylegroundForm)

    interactionData.formContainerGroup = stylegroundFormGroup
    interactionData.stylegroundPreviewGroup = stylegroundPreview

    local stylegroundListPreviewRow = uiElements.row({
        stylegroundListColumn:with(uiUtils.fillHeight(false)),
        stylegroundPreview
    }):with(uiUtils.fillHeight(true))

    local layout = uiElements.column({
        stylegroundListPreviewRow,
        stylegroundFormGroup
    }):with(uiUtils.fillHeight(true))

    layout:reflow()

    return layout, interactionData
end

function stylegroundWindow.editStylegrounds(map)
    local window
    local layout, interactionData = getWindowContent(map)

    -- Figure out some smart sizing things here, this is too hardcoded
    -- Still doesn't fit all the elements, good enough for now
    window = uiElements.window("Styleground Window", layout):with({
        height = WINDOW_STATIC_HEIGHT
    })

    table.insert(activeWindows, window)
    stylegroundWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function stylegroundWindow.getWindow()
    stylegroundEditor.stylegroundWindow = stylegroundWindow

    return stylegroundWindowGroup
end

return stylegroundWindow