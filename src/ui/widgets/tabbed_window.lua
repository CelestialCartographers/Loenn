local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local widgetUtils = require("ui.widgets.utils")

local tabbedWindow = {}

function tabbedWindow.createWindow(title, tabs, initialTab)
    initialTab = initialTab or 1

    local tabContent = uiElements.group({
        tabs[initialTab].content
    })
    local windowTabItems = {}

    for i, tab in ipairs(tabs) do
        table.insert(windowTabItems, {
            text = tab.title,
            data = i,
            content = tab.content
        })
    end

    local function tabsCallback(list, target)
        local newChild = windowTabItems[target].content

        tabContent:removeChild(tabContent.children[1])
        tabContent:addChild(newChild)
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
    })
    local window = uiElements.window(title, windowContent)

    return window, windowContent
end

return tabbedWindow
