-- TODO - Add texture dropdown options
-- Currently too slow both in window creation and when clicking around in the style list

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
local parallaxStruct = require("structs.parallax")
local effectStruct = require("structs.effect")
local formUtils = require("ui.utils.forms")
local atlases = require("atlases")

local stylegroundWindow = {}

local parallaxTextureOptions

local activeWindows = {}
local windowPreviousX = 0
local windowPreviousY = 0

local stylegroundWindowGroup = uiElements.group({}):with({

})

-- TODO - Layouting variables that should be more dyanmic
local PREVIEW_MAX_WIDTH = 320 * 3
local PREVIEW_MAX_HEIGHT = 180 * 3
local WINDOW_STATIC_HEIGHT = 640

local function cacheParallaxTextureOptions()
    local options = parallax.getParallaxNames()

    table.sort(options)

    parallaxTextureOptions = options
end

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

    -- Add cached texture options
    if utils.typeof(style) == "parallax" then
        options.fields.texture.options = parallaxTextureOptions
    end

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

function stylegroundWindow.getStylegroundPreview(interactionData)
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
function stylegroundWindow.updateStylegroundPreview(interactionData)
    local previewContainer = interactionData.stylegroundPreviewGroup
    local newPreview = stylegroundWindow.getStylegroundPreview(interactionData)

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

local function applyFormChanges(style, newData)
    -- TODO - Handle parent better, ignore for now

    for k, v in pairs(newData) do
        style[k] = v
    end
end

-- Returns values as follows:
-- First is fg/bg styles table from the map
-- Second is the actual parent of the style (styles table or an apply)
-- Third is the index in that parent
-- Fourth is the parent style, if it exists
local function findStyleInStylegrounds(interactionData)
    local listTarget = interactionData.listTarget

    if not listTarget then
        return
    end

    local map = interactionData.map
    local style = interactionData.listTarget.style
    local foreground = interactionData.listTarget.foreground
    local styles = foreground and map.stylesFg or map.stylesBg

    for i, s in ipairs(styles) do
        local styleType = utils.typeof(s)

        if style == s then
            return styles, styles, i
        end

        if styleType == "apply" then
            for j, c in ipairs(s.children or {}) do
                if style == c then
                    return styles, s.children, j, s
                end
            end
        end
    end

    return styles, styles, 1
end

local function findCurrentListItem(interactionData)
    local listTarget = interactionData.listTarget
    local listElement = interactionData.stylegroundListElement

    for i, item in ipairs(listElement.children) do
        if item.data == listTarget then
            return item, i
        end
    end
end

local function foregroundListItemCount(interactionData)
    local listElement = interactionData.stylegroundListElement
    local count = 0

    for _, item in ipairs(listElement.children) do
        if item.data.foreground then
            count += 1
        end
    end

    return count
end

local function setSelectionWithCallback(listElement, index)
    listElement:setSelectedIndex(utils.clamp(index, 1, #listElement.children))

    local newSelection = listElement.selected

    if newSelection then
        -- Trigger list item callback
        newSelection:onClick(0, 0, 1)
    end

    return newSelection
end

function moveIndex(t, before, after)
    local value = table.remove(t, before)

    table.insert(t, after, value)
end

local function canMoveStyle(interactionData, offset)
    local listTarget = interactionData.listTarget

    if not listTarget or listTarget.defaultTarget then
        return false
    end

    local styles, parent, index = findStyleInStylegrounds(interactionData)

    if parent and index then
        local newIndex = utils.clamp(index + offset, 1, #parent)

        return index ~= newIndex
    end

    return false
end

local function moveStyle(interactionData, offset, moveUpButton, moveDownButton)
    local styles, parent, index = findStyleInStylegrounds(interactionData)

    if parent and index then
        local newIndex = utils.clamp(index + offset, 1, #parent)

        if index ~= newIndex then
            local listElement = interactionData.stylegroundListElement
            local listItem, listIndex = findCurrentListItem(interactionData)

            moveIndex(parent, index, newIndex)
            moveIndex(listElement.children, listIndex, listIndex + offset)

            listElement:reflow()

            if moveUpButton and moveDownButton then
                moveUpButton:formSetEnabled(canMoveStyle(interactionData, -1))
                moveDownButton:formSetEnabled(canMoveStyle(interactionData, 1))
            end
        end
    end
end

local function createParallax()
    local style = parallaxStruct.decode()
    local defaultData = parallax.defaultData(style) or {}

    for k, v in pairs(defaultData) do
        style[k] = v
    end

    return style
end

local function createEffect(name)
    local style = effectStruct.decode({__name = name})
    local defaultData = effects.defaultData(style) or {}

    for k, v in pairs(defaultData) do
        style[k] = v
    end

    return style
end

-- For when the list is completely empty
local function getDefaultListTarget()
    return {
        style = createParallax(),
        foreground = true,
        defaultTarget = true
    }
end

local function changeStyleForeground(interactionData, moveUpButton, moveDownButton)
    local listTarget = interactionData.listTarget
    local listElement = interactionData.stylegroundListElement
    local listItem, listIndex = findCurrentListItem(interactionData)

    local foreground = listTarget.foreground
    local foregroundCount = foregroundListItemCount(interactionData)

    local styles, parent, index, parentStyle = findStyleInStylegrounds(interactionData)
    local parentType = utils.typeof(parentStyle)

    local movedStyle = listTarget.style
    local map = interactionData.map

    local insertionIndex = foreground and #listElement.children or foregroundCount + 1
    local firstIndex = listIndex
    local lastIndex = listIndex

    -- Move all related menu items
    if parentType == "apply" then
        movedStyle = parentStyle
        firstIndex = listIndex - index + 1
        lastIndex = firstIndex + #parent - 1
    end

    -- Reorder list items
    local fromIndex = firstIndex

    for i = firstIndex, lastIndex do
        local movedItem = listElement.children[fromIndex]

        movedItem.label.value = not foreground
        movedItem.data.foreground = not foreground

        moveIndex(listElement.children, fromIndex, insertionIndex)

        -- The list only shifts around when going from background -> foreground
        if not foreground then
            fromIndex += 1
            insertionIndex += 1
        end

    end

    -- Update map style data
    local fromStyles = foreground and map.stylesFg or map.stylesBg
    local toStyles = foreground and map.stylesBg or map.stylesFg

    for i, s in ipairs(fromStyles) do
        if movedStyle == s then
            table.remove(fromStyles, i)
            table.insert(toStyles, movedStyle)

            break
        end
    end

    -- Update list and form fields
    listElement:reflow()
    listItem:onClick(0, 0, 1)
end

local function addNewStyle(interactionData, formFields, moveUpButton, moveDownButton)
    local listTarget = interactionData.listTarget

    local newStyle
    local currentStyle = listTarget.style
    local parentStyle = listTarget.parentStyle

    local listElement = interactionData.stylegroundListElement
    local foreground = listTarget.foreground
    local map = interactionData.map
    local method = interactionData.addNewMethod.method
    local correctForegroundValue = interactionData.addNewMethod.correctForegroundValue
    local listItems = {}

    if method == "basedOnCurrent" then
        if currentStyle then
            newStyle = table.shallowcopy(currentStyle)

            applyFormChanges(newStyle, form.getFormData(formFields))
        end

    elseif method == "parallax" then
        newStyle = createParallax()

    elseif method == "effect" then
        local effectName = interactionData.addNewMethod.name

        newStyle = createEffect(effectName)
    end

    if newStyle then
        local styles, parentTable, index = findStyleInStylegrounds(interactionData, foreground)
        local _, listIndex = findCurrentListItem(interactionData)
        local listItems = getStylegroundItems({newStyle}, foreground, {}, nil)

        -- Fallback if we don't have any items in the list yet
        if #listElement.children == 0 then
            parentTable = foreground and map.stylesFg or map.stylesBg
            listIndex = 0
            index = 0
        end

        for i, item in ipairs(listItems) do
            local listItem = uiElements.listItem(item.text, item.data)

            listItem.owner = listElement

            table.insert(listElement.children, listIndex + i, listItem)
        end

        table.insert(parentTable, index + 1, newStyle)

        if #listItems > 0 then
            local lastItem = listElement.children[listIndex + #listItems]

            listElement:reflow()
            lastItem:onClick(0, 0, 1)

            if correctForegroundValue == false then
                changeStyleForeground(interactionData, moveUpButton, moveDownButton)
            end
        end
    end

    return not not newStyle
end

local function removeStyle(interactionData)
    local styles, parent, index = findStyleInStylegrounds(interactionData)

    if parent and index then
        local listElement = interactionData.stylegroundListElement
        local listItem, listIndex = findCurrentListItem(interactionData)

        table.remove(parent, index)
        listItem:removeSelf()

        if #listElement.children > 0 then
            setSelectionWithCallback(listElement, listIndex)

        else
            interactionData.listTarget = getDefaultListTarget()

            stylegroundWindow.updateStylegroundForm(interactionData)
            stylegroundWindow.updateStylegroundPreview(interactionData)
        end
    end
end

local function updateListItemText(listItem, style)
    if not listItem then
        return
    end

    local styleType = utils.typeof(style)
    local language = languageRegistry.getLanguage()

    if styleType == "parallax" then
        listItem.text = parallax.displayName(language, style)

    elseif styleType == "effect" then
        listItem.text = effects.displayName(language, style)
    end
end

local function updateStyle(interactionData, style, newData)
    local listElement = interactionData.stylegroundListElement
    local listItem = listElement and listElement.selected

    applyFormChanges(style, newData)
    updateListItemText(listItem, style)
end

local function getNewDropdownOptions(style, foreground, usingDefault)
    local language = languageRegistry.getLanguage()
    local knownEffects = effects.registeredEffects
    local options = {}

    if style and not usingDefault then
        table.insert(options, {
            text = tostring(language.ui.styleground_window.new_options.based_on_current),
            data = {
                method = "basedOnCurrent"
            }
        })
    end

    table.insert(options, {
        text = tostring(language.ui.styleground_window.new_options.parallax),
        data = {
            method = "parallax"
        }
    })

    -- Find all effects and add them in sorted order (by display name)
    local effectOptions = {}

    for name, handler in pairs(knownEffects) do
        local fakeEffect = {_name = name}
        local displayName = effects.displayName(language, fakeEffect)
        local canForeground = effects.canForeground(fakeEffect)
        local canBackground = effects.canBackground(fakeEffect)

        table.insert(effectOptions, {
            text = displayName,
            data = {
                method = "effect",
                name = name,
                correctForegroundValue = foreground and canForeground or not foreground and canBackground
            }
        })
    end

    effectOptions = table.sortby(effectOptions, function(option)
        return option.text
    end)()

    for _, option in ipairs(effectOptions) do
        table.insert(options, option)
    end

    return options
end

local function getStylegroundFormButtons(interactionData, formFields, formOptions)
    local listTarget = interactionData.listTarget or {}
    local listHasElements = false

    if interactionData.stylegroundListElement then
        listHasElements = #interactionData.stylegroundListElement.children > 0
    end

    local language = languageRegistry.getLanguage()
    local style = listTarget.style
    local foreground = listTarget.foreground
    local isDefaultTarget = listTarget.defaultTarget

    local handler = getHandler(style)

    local canForeground = handler and handler.canForeground(style)
    local canBackground = handler and handler.canBackground(style)
    local canChangeForeground = canForeground and canBackground

    local moveToForegroundText = tostring(language.ui.styleground_window.form.move_to_foreground)
    local moveToBackgroundText = tostring(language.ui.styleground_window.form.move_to_background)

    local movementButtonElements = {}
    local changeForegroundButton = {
        text = foreground and moveToBackgroundText or moveToForegroundText,
        callback = function(formFields)
            changeStyleForeground(interactionData, movementButtonElements.up, movementButtonElements.down)
        end
    }
    local buttons = {
        {
            text = tostring(language.ui.styleground_window.form.new),
            callback = function(formFields)
                addNewStyle(interactionData, formFields, movementButtonElements.up, movementButtonElements.down)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.remove),
            enabled = listHasElements,
            callback = function(formFields)
                removeStyle(interactionData)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.update),
            formMustBeValid = true,
            enabled = listHasElements,
            callback = function(formFields)
                updateStyle(interactionData, style, form.getFormData(formFields))
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.move_up),
            enabled = canMoveStyle(interactionData, -1),
            callback = function(formFields)
                moveStyle(interactionData, -1, movementButtonElements.up, movementButtonElements.down)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.move_down),
            enabled = canMoveStyle(interactionData, 1),
            callback = function(formFields)
                moveStyle(interactionData, 1, movementButtonElements.up, movementButtonElements.down)
            end
        }
    }

    if canChangeForeground and listHasElements then
        table.insert(buttons, changeForegroundButton)
    end

    local buttonRow = formHelper.getFormButtonRow(buttons, formFields, formOptions)
    local newDropdownItems = getNewDropdownOptions(style, foreground, isDefaultTarget)
    local newDropdown = uiElements.dropdown(newDropdownItems, function(item, data)
        interactionData.addNewMethod = data
    end)

    -- Reference for movement button "enable" updates
    movementButtonElements.up = buttonRow.children[4]
    movementButtonElements.down = buttonRow.children[5]

    interactionData.addNewMethod = newDropdownItems[1].data

    table.insert(buttonRow.children, 1, newDropdown)

    return buttonRow
end

function stylegroundWindow.getStylegroundForm(interactionData)
    local formData = prepareFormData(interactionData)
    local formOptions, dummyData = getOptions(formData)

    -- TODO - Add to config file?
    formOptions.columns = 8
    formOptions.formFieldChanged = function(formFields, field)
        local newData = form.getFormData(formFields)

        interactionData.formData = newData

        stylegroundWindow.updateStylegroundPreview(interactionData)
    end

    local formBody, formFields = formHelper.getFormBody(dummyData, formOptions, buttons)
    local buttonRow = getStylegroundFormButtons(interactionData, formFields, formOptions)

    return uiElements.column({formBody, buttonRow})
end

function stylegroundWindow.updateStylegroundForm(interactionData)
    local formContainer = interactionData.formContainerGroup
    local newForm = stylegroundWindow.getStylegroundForm(interactionData)

    if formContainer.children[1] then
        formContainer:removeChild(formContainer.children[1])
    end

    formContainer:addChild(newForm)
end

function stylegroundWindow.getStylegroundList(map, interactionData)
    local items = {}

    getStylegroundItems(map.stylesFg or {}, true, items)
    getStylegroundItems(map.stylesBg or {}, false, items)

    local column, list = listWidgets.getList(function(element, listItem)
        interactionData.listTarget = listItem
        interactionData.formData = prepareFormData(interactionData)

        stylegroundWindow.updateStylegroundForm(interactionData)
        stylegroundWindow.updateStylegroundPreview(interactionData)
    end, items, {initialItem = 1})

    return column, list
end

function stylegroundWindow.getWindowContent(map)
    local interactionData = {}

    -- See TODO at top of file
    --cacheParallaxTextureOptions()

    interactionData.map = map
    interactionData.listTarget = getDefaultListTarget()

    local stylegroundFormGroup = uiElements.group({}):with(uiUtils.bottombound)
    local stylegroundListColumn, stylegroundList = stylegroundWindow.getStylegroundList(map, interactionData)
    local stylegroundPreview = uiElements.group({
        stylegroundWindow.getStylegroundPreview(interactionData)
    })
    local stylegroundForm = stylegroundWindow.getStylegroundForm(interactionData)

    stylegroundFormGroup:addChild(stylegroundForm)

    interactionData.formContainerGroup = stylegroundFormGroup
    interactionData.stylegroundPreviewGroup = stylegroundPreview
    interactionData.stylegroundListElement = stylegroundList

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
    if not map then
        return
    end

    local window
    local layout, interactionData = stylegroundWindow.getWindowContent(map)

    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.styleground_window.window_title)

    -- Figure out some smart sizing things here, this is too hardcoded
    -- Still doesn't fit all the elements, good enough for now
    window = uiElements.window(windowTitle, layout):with({
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