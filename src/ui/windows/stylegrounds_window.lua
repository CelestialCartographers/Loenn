-- TODO - Add texture dropdown options
-- Currently too slow both in window creation and when clicking around in the style list

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local languageRegistry = require("language_registry")
local utils = require("utils")
local form = require("ui.forms.form")
local stylegroundEditor = require("ui.styleground_editor")
local listWidgets = require("ui.widgets.lists")
local widgetUtils = require("ui.widgets.utils")
local formHelper = require("ui.forms.form")
local parallax = require("parallax")
local effects = require("effects")
local apply = require("apply")
local applyStruct = require("structs.apply")
local parallaxStruct = require("structs.parallax")
local effectStruct = require("structs.effect")
local formUtils = require("ui.utils.forms")
local atlases = require("atlases")
local tabbedWindow = require("ui.widgets.tabbed_window")
local listItemUtils = require("ui.utils.list_item")

local windowPersister = require("ui.window_position_persister")
local windowPersisterName = "stylegrounds_window"

local stylegroundWindow = {}

local parallaxTextureOptions

local stylegroundWindowGroup = uiElements.group({})

-- TODO - Layouting variables that should be more dyanmic
local PREVIEW_MAX_WIDTH = 320 * 3
local PREVIEW_MAX_HEIGHT = 180 * 3
local WINDOW_STATIC_HEIGHT = 640

local function cacheParallaxTextureOptions()
    local options = parallax.getParallaxNames()

    table.sort(options)

    parallaxTextureOptions = options
end

local function addFolderIndent(text)
    return " - " .. text
end

local function getStylegroundItems(targets, items, foreground, parent)
    local language = languageRegistry.getLanguage()
    local groupIndex = 1

    items = items or {}

    for _, style in ipairs(targets) do
        local styleType = utils.typeof(style)

        if styleType == "parallax" then
            local displayName = parallax.displayName(language, style)

            table.insert(items, {
                text = displayName,
                data = {
                    style = style,
                    parentStyle = parent,
                    foreground = foreground,
                }
            })

        elseif styleType == "effect" then
            local displayName = effects.displayName(language, style)

            table.insert(items, {
                text = displayName,
                data = {
                    style = style,
                    parentStyle = parent,
                    foreground = foreground,
                }
            })

        elseif styleType == "apply" then
            if style.children then
                local childItems = {}

                getStylegroundItems(style.children, childItems, foreground, style)

                local groupText = apply.displayName(language, style, groupIndex)
                local groupLabel = uiElements.label(groupText)
                local listItemData = {
                    style = style,
                    parentStyle = parent,
                    foreground = foreground,
                }

                -- Fake list item
                local groupItem = uiElements.row({groupLabel}):with({
                    label = groupLabel,
                    style = {
                        spacing = uiElements.listItem.style.spacing
                    }
                })

                -- TODO - Get proper icons
                listItemUtils.setIcon(groupItem, "favorite")

                table.insert(items, {
                    text = groupItem,
                    data = listItemData,
                    foreground = foreground,
                })

                for _, child in ipairs(childItems) do
                    child.text = addFolderIndent(child.text)

                    table.insert(items, child)
                end

                groupIndex += 1
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

    elseif styleType == "apply" then
        return apply
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
            local bestScale = utils.getBestScale(imageWidth, imageHeight, PREVIEW_MAX_WIDTH, PREVIEW_MAX_HEIGHT)

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
-- Fifth is the index the target would have in the visual list
local function findStyleInStylegrounds(interactionData, target)
    local listIndex = 0
    local listTarget = interactionData.listTarget
    local style = target

    if not listTarget then
        return
    end

    style = style or interactionData.listTarget.style

    local map = interactionData.map
    local foreground = interactionData.listTarget.foreground
    local styles = foreground and map.stylesFg or map.stylesBg

    for i, s in ipairs(styles) do
        listIndex += 1

        if style == s then
            return styles, styles, i, nil, listIndex
        end

        local styleType = utils.typeof(s)

        if styleType == "apply" then
            for j, c in ipairs(s.children or {}) do
                listIndex += 1

                if style == c then
                    return styles, s.children, j, s, listIndex
                end
            end
        end
    end

    return styles, styles, 1, nil, 1
end

local function findListIndex(interactionData, targetStyle)
    local _, _, _, _, listIndex = findStyleInStylegrounds(interactionData, targetStyle)

    return listIndex
end

local function findListItem(interactionData, targetStyle)
    local listElement = interactionData.stylegroundListElement

    for i, item in ipairs(listElement.children) do
        if item.data.style == targetStyle then
            return item, i
        end
    end
end

local function findCurrentListItem(interactionData)
    local listTarget = interactionData.listTarget

    return findListItem(interactionData, listTarget.style)
end

local function moveIndex(t, before, after)
    local value = table.remove(t, before)

    table.insert(t, after, value)
end

local function canMoveStyle(interactionData, offset)
    local listTarget = interactionData.listTarget

    if not listTarget or listTarget.defaultTarget then
        return false
    end

    local _, parent, index = findStyleInStylegrounds(interactionData)

    if parent and index then
        local newIndex = index + offset

        return index ~= newIndex and newIndex >= 1 and newIndex <= #parent
    end

    return false
end

local function updateMovementButtons(interactionData)
    local moveUpButton = interactionData.movementButtonElements.up
    local moveDownButton = interactionData.movementButtonElements.down

    if moveUpButton and moveDownButton then
        moveUpButton:formSetEnabled(canMoveStyle(interactionData, -1))
        moveDownButton:formSetEnabled(canMoveStyle(interactionData, 1))
    end
end

local function moveStyle(interactionData, offset)
    local styles, parent, index = findStyleInStylegrounds(interactionData)

    if parent and index then
        local newIndex = utils.clamp(index + offset, 1, #parent)

        if index ~= newIndex then
            local listElement = interactionData.stylegroundListElement
            local _, listIndex = findCurrentListItem(interactionData)
            local movingGroup = styles == parent

            moveIndex(parent, index, newIndex)

            if movingGroup then
                local newListIndex = findListIndex(interactionData, style)

                interactionData.rebuildListItems(newListIndex)

            else
                moveIndex(listElement.children, listIndex, listIndex + offset)
            end

            listElement:reflow()

            updateMovementButtons(interactionData)
        end
    end
end

local function createApply()
    local style = applyStruct.decode({})
    local defaultData = apply.defaultData(style) or {}

    for k, v in pairs(defaultData) do
        style[k] = v
    end

    return style
end

local function createParallax()
    local style = parallaxStruct.decode({})
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

local function changeStyleForeground(interactionData)
    local listTarget = interactionData.listTarget
    local currentListElement = interactionData.stylegroundListElement
    local otherListElement = interactionData.stylegroundListElementOther

    local foreground = listTarget.foreground

    local movedStyle = listTarget.style
    local map = interactionData.map

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

    interactionData.rebuildListItems(nil, otherListElement)
    interactionData.rebuildListItems(nil, currentListElement)
end

local function addNewStyle(interactionData, formFields)
    local listTarget = interactionData.listTarget

    local newStyle
    local currentStyle = listTarget.style
    local parentStyle = listTarget.parentStyle

    local listElement = interactionData.stylegroundListElement
    local foreground = listElement == interactionData.stylegroundListElementFg
    local map = interactionData.map
    local method = interactionData.addNewMethod.method

    if method == "basedOnCurrent" then
        if currentStyle then
            newStyle = utils.deepcopy(currentStyle)

            applyFormChanges(newStyle, form.getFormData(formFields))
        end

    elseif method == "group" then
        newStyle = createApply()

    elseif method == "parallax" then
        newStyle = createParallax()

    elseif method == "effect" then
        local effectName = interactionData.addNewMethod.name

        newStyle = createEffect(effectName)
    end

    if newStyle then
        local _, parentTable, index = findStyleInStylegrounds(interactionData)
        local _, listIndex = findCurrentListItem(interactionData)
        local targetGroup
        local newIsApply = utils.typeof(newStyle) == "apply"
        local currentIsApply = utils.typeof(currentStyle) == "apply"
        local parentIsApply = utils.typeof(parentStyle) == "apply"

        if currentIsApply then
            targetGroup = currentStyle

            -- We are adding as first element of the group
            index = 0

        elseif parentIsApply then
            targetGroup = parentStyle
        end

        local addToGroup = targetGroup and not newIsApply

        -- If we add a apply it should be added after the current group
        if newIsApply and targetGroup then
            parentTable = foreground and map.stylesFg or map.stylesBg
            _, _, index, _, listIndex = findStyleInStylegrounds(interactionData, targetGroup)
            listIndex += #targetGroup.children
        end

        -- Fallback if we don't have any items in the list yet
        if #listElement.children == 0 then
            addToGroup = false
            parentTable = foreground and map.stylesFg or map.stylesBg
            listIndex = 0
            index = 0
        end

        if addToGroup then
            if not targetGroup.children then
                targetGroup.children = {}
            end

            table.insert(targetGroup.children, index + 1, newStyle)

        else
            table.insert(parentTable, index + 1, newStyle)
        end

        -- Update list index after adding group
        if newIsApply and parentIsApply then
            listIndex = findListIndex(interactionData, newStyle) - 1
        end

        interactionData.rebuildListItems(listIndex + 1)
    end

    return not not newStyle
end

local function removeStyle(interactionData)
    local _, parent, index = findStyleInStylegrounds(interactionData)

    if parent and index then
        local _, listIndex = findCurrentListItem(interactionData)

        table.remove(parent, index)

        local newItems = interactionData.rebuildListItems(listIndex or 1)

        if #newItems == 0 then
            interactionData.listTarget = getDefaultListTarget()

            stylegroundWindow.updateStylegroundForm(interactionData)
            stylegroundWindow.updateStylegroundPreview(interactionData)
        end
    end
end

local function updateStyle(interactionData, style, newData)
    applyFormChanges(style, newData)
    interactionData.rebuildListItems()
end

local function getNewDropdownOptions(style, foreground, usingDefault, showIncorrect)
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
        text = tostring(language.ui.styleground_window.new_options.apply),
        data = {
            method = "group"
        }
    })

    table.insert(options, {
        text = tostring(language.ui.styleground_window.new_options.parallax),
        data = {
            method = "parallax"
        }
    })

    -- Find all effects and add them in sorted order (by display name)
    local effectOptions = {}

    for name, _ in pairs(knownEffects) do
        local fakeEffect = {_name = name}
        local displayName = effects.displayName(language, fakeEffect)
        local canForeground = effects.canForeground(fakeEffect)
        local canBackground = effects.canBackground(fakeEffect)
        local correctForegroundValue = foreground and canForeground or not foreground and canBackground

        local option = {
            text = displayName,
            data = {
                method = "effect",
                name = name,
                correctForegroundValue = correctForegroundValue
            }
        }

        -- Remove invalid options that does not match current foreground/background
        if showIncorrect or correctForegroundValue then
            table.insert(effectOptions, option)
        end
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
    local inGroup = not not listTarget.parentStyle

    local handler = getHandler(style)

    local canForeground = handler and handler.canForeground(style)
    local canBackground = handler and handler.canBackground(style)
    local canChangeForeground = canForeground and canBackground and not inGroup

    local moveToForegroundText = tostring(language.ui.styleground_window.form.move_to_foreground)
    local moveToBackgroundText = tostring(language.ui.styleground_window.form.move_to_background)

    local movementButtonElements = {}
    local changeForegroundButton = {
        text = foreground and moveToBackgroundText or moveToForegroundText,
        callback = function()
            changeStyleForeground(interactionData)
        end
    }

    interactionData.movementButtonElements = movementButtonElements

    local buttons = {
        {
            text = tostring(language.ui.styleground_window.form.new),
            callback = function()
                addNewStyle(interactionData, formFields)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.remove),
            enabled = listHasElements,
            callback = function()
                removeStyle(interactionData)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.update),
            formMustBeValid = true,
            enabled = listHasElements,
            callback = function()
                updateStyle(interactionData, style, form.getFormData(formFields))
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.move_up),
            enabled = canMoveStyle(interactionData, -1),
            callback = function()
                moveStyle(interactionData, -1)
            end
        },
        {
            text = tostring(language.ui.styleground_window.form.move_down),
            enabled = canMoveStyle(interactionData, 1),
            callback = function()
                moveStyle(interactionData, 1)
            end
        }
    }

    if canChangeForeground and listHasElements then
        table.insert(buttons, changeForegroundButton)
    end

    local buttonRow = formHelper.getFormButtonRow(buttons, formFields, formOptions)
    local newDropdownItems = getNewDropdownOptions(style, foreground, isDefaultTarget)
    local newDropdown = uiElements.dropdown(newDropdownItems, function(_, data)
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
    formOptions.formFieldChanged = function(formFields)
        local newData = form.getFormData(formFields)

        interactionData.formData = newData

        stylegroundWindow.updateStylegroundPreview(interactionData)
    end

    local formBody, formFields = formHelper.getFormBody(dummyData, formOptions)
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

-- Check if movement is allowed and return prepared offset and interactionData
local function listItemDragAllowed(interactionData, fromList, fromListItem, _, _, fromIndex, toIndex)
    local offset = toIndex - fromIndex

    if toIndex > fromIndex then
        offset -= 1
    end

    if offset ~= 0 then
        local fakeInteractionData = table.shallowcopy(interactionData)

        fakeInteractionData.listTarget = fromListItem.data
        fakeInteractionData.stylegroundListElement = fromList

        return canMoveStyle(fakeInteractionData, offset), offset, fakeInteractionData
    end

    return false, offset, nil
end

local function listItemDraggedHandler(interactionData)
    return function(fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
        local allowed, offset, fakeInteraction = listItemDragAllowed(interactionData, fromList, fromListItem, toList, toListItem, fromIndex, toIndex)

        if allowed then
            moveStyle(fakeInteraction, offset)

            -- Force update movement buttons with the real data
            -- We might have moved in a way that should disable/enable some buttons
            updateMovementButtons(interactionData)
        end

        -- Manually update the list
        return false
    end
end

local function listItemCanInsertHandler(interactionData)
    return function(fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
        return listItemDragAllowed(interactionData, fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
    end
end

function stylegroundWindow.getStylegroundListItems(map, fg)
    local items = {}
    local styles = fg and map.stylesFg or map.stylesBg

    getStylegroundItems(styles or {}, items, fg)

    return items
end

function stylegroundWindow.getStylegroundList(map, interactionData, fg)
    local items = stylegroundWindow.getStylegroundListItems(map, fg)

    local listOptions = {
        initialItem = 1,
        draggable = true,
        listItemDragged = listItemDraggedHandler(interactionData),
        listItemCanInsert = listItemCanInsertHandler(interactionData)
    }

    local column, list = listWidgets.getList(function(element, listItem)
        interactionData.listTarget = listItem
        interactionData.formData = prepareFormData(interactionData)

        stylegroundWindow.updateStylegroundForm(interactionData)
        stylegroundWindow.updateStylegroundPreview(interactionData)
    end, items, listOptions)

    list:layout()

    return column, list, items
end

function stylegroundWindow.getWindowContent(map)
    local interactionData = {}
    local language = languageRegistry.getLanguage()

    -- See TODO at top of file
    --cacheParallaxTextureOptions()

    interactionData.map = map
    interactionData.listTarget = getDefaultListTarget()

    local stylegroundFormGroup = uiElements.group({}):with(uiUtils.bottombound)
    local stylegroundPreview = uiElements.group({
        stylegroundWindow.getStylegroundPreview(interactionData)
    })
    local stylegroundForm = stylegroundWindow.getStylegroundForm(interactionData)

    stylegroundFormGroup:addChild(stylegroundForm)

    -- Create foreground last because of list callbacks
    local listColumnBackground, listBackground = stylegroundWindow.getStylegroundList(map, interactionData, false)
    local listColumnForeground, listForeground = stylegroundWindow.getStylegroundList(map, interactionData, true)

    interactionData.formContainerGroup = stylegroundFormGroup
    interactionData.stylegroundPreviewGroup = stylegroundPreview
    interactionData.stylegroundListElementFg = listForeground
    interactionData.stylegroundListElementBg = listBackground

    function interactionData.rebuildListItems(listTarget, list)
        if not list then
            list = interactionData.stylegroundListElement
        end

        local fg = list == interactionData.stylegroundListElementFg
        local newItems = stylegroundWindow.getStylegroundListItems(map, fg)

        -- Use current target if none specified
        if not listTarget then
            listTarget = list:getSelectedIndex()
        end

        list:updateItems(newItems, listTarget)

        return newItems
    end

    local tabs = {
        {
            title = tostring(language.ui.styleground_window.tab_foreground),
            content = listColumnForeground,
            callback = function()
                interactionData.stylegroundListElement = listForeground
                interactionData.stylegroundListElementOther = listBackground

                ui.runLate(function()
                    widgetUtils.focusElement(listForeground.children[1])
                    listForeground:setSelection(listForeground:getSelectedData(), false, false)
                end)
            end,
        },
        {
            title = tostring(language.ui.styleground_window.tab_background),
            content = listColumnBackground,
            callback = function()
                interactionData.stylegroundListElement = listBackground
                interactionData.stylegroundListElementOther = listForeground

                ui.runLate(function()
                    widgetUtils.focusElement(listBackground.children[1])
                    listBackground:setSelection(listBackground:getSelectedData(), false, false)
                end)
            end,
        },
    }
    local tabbedWindowOptions = {
        respectSiblings = false
    }
    local _, tabbedContent = tabbedWindow.createWindow("", tabs, tabbedWindowOptions)

    local stylegroundListPreviewRow = uiElements.row({
        tabbedContent,
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
    local layout = stylegroundWindow.getWindowContent(map)

    local language = languageRegistry.getLanguage()
    local windowTitle = tostring(language.ui.styleground_window.window_title)

    -- Figure out some smart sizing things here, this is too hardcoded
    -- Still doesn't fit all the elements, good enough for now
    window = uiElements.window(windowTitle, layout):with({
        height = WINDOW_STATIC_HEIGHT
    })

    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)

    windowPersister.trackWindow(windowPersisterName, window)
    stylegroundWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    widgetUtils.preventOutOfBoundsMovement(window)

    return window
end

-- Group to get access to the main group and sanely inject windows in it
function stylegroundWindow.getWindow()
    stylegroundEditor.stylegroundWindow = stylegroundWindow

    return stylegroundWindowGroup
end

return stylegroundWindow