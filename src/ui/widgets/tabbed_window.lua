local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local tabbedWindow = {}

function tabbedWindow.createWindow(title, tabs, initialTab)
    initialTab = initialTab or 1

    local tabContent = tabs[initialTab].content
    local windowTabItems = {}

    for i, tab in ipairs(tabs) do
        table.insert(windowTabItems, {
            text = tab.title,
            data = i,
            content = tab.content
        })
    end

    local function tabsCallback(list, target)
        local parent = list.parent
        local newChild = windowTabItems[target].content

        while #parent.children > 1 do
            parent:removeChild(parent.children[#parent.children])
        end

        -- Check if new child is column, automatically use its children if it is
        -- Add all elements if table, otherwise add the single element

        local childType = newChild.__type

        if childType == "column" then
            newChild = newChild.children
        end

        if #newChild > 0 then
            for _, nc in ipairs(newChild) do
                list.parent:addChild(nc)
            end

        else
            list.parent:addChild(newChild)
        end
    end

    local tabsElement = uiElements.listH(windowTabItems, tabsCallback):with(
        uiUtils.fillWidth(false)
    )
    local initialListItem = tabsElement.children[initialTab]

    initialListItem.owner = tabsElement
    initialListItem:setSelected(windowTabItems[initialTab])

    local windowContent = uiElements.column({
        tabsElement,
        tabContent
    }):with({
        minWidth = 128
    }):with(uiUtils.fillHeight(true))

    local window = uiElements.window(title, windowContent)

    return window, windowContent
end

return tabbedWindow
