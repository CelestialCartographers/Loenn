local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local iconUtils = require("ui.utils.icons")

local listItemUtils = {}

-- Get icon that would fit inside the list item
function listItemUtils.getIcon(listItem, iconName)
    if listItem.height <= 0 then
        listItem:layout()
    end

    local iconOffsetX = listItem.style.padding
    local iconMaxSize = listItem.height - listItem.style.padding * 2
    local listIcon, iconSize = iconUtils.getIcon(iconName, iconMaxSize)

    if listIcon then
        local centerOffset = math.floor((listItem.height - iconSize) / 2)
        local imageElement = uiElements.image(listIcon)

        imageElement = imageElement:with(uiUtils.at(iconOffsetX, centerOffset))

        return imageElement, iconSize
    end
end

-- Add icon to the list item, override text as well if provided
function listItemUtils.setIcon(listItem, iconName, callback, newText)
    local previousLabel = listItem.label
    local children = listItem.children

    if not children then
        return
    end

    if newText then
        previousLabel.text = newText
    end

    local listIconImage = listItemUtils.getIcon(listItem, iconName)

    for i = 1, #children do
        children[i] = nil
    end

    if listIconImage then
        table.insert(children, listIconImage)

        if callback then
            listIconImage.interactive = 1
            listIconImage:hook({
                onPress = function(orig, self, ...)
                    -- Use the list item instead of icon
                    local consume = callback(listItem, ...)

                    if consume == false then
                        orig(self, ...)
                    end
                end
            })
        end
    end

    table.insert(children, previousLabel)

    listItem:layout()
    listItem:layoutLate()

    if listItem.parent then
        listItem.parent:layoutLate()
    end

    return listIconImage
end

-- Clear icon on list item
function listItemUtils.clearIcon(listItem, newText)
    listItemUtils.setIcon(listItem, nil, newText)
end

return listItemUtils