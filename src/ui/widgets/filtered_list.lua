local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local filteredList = {}

local function layoutWidthUpdate(orig, element)
    local parentWidth = element.parent.innerWidth

    if element.width < parentWidth then
        element.width = parentWidth
        element.innerWidth = parentWidth - element.style.padding * 2
    end

    orig(element)
end

local function calculateWidth(orig, element)
    return element.inner.width
end

local function filterItems(items, search)
    local filtered = {}

    for _, item in ipairs(items) do
        if item.text:contains(search) then
            table.insert(filtered, item)
        end
    end

    return filtered
end

local function setSelection(list, target)
    -- Select first item as default, callback if it exists
    -- If target is defined attempt to select this instead of the first item

    local previousSelection = list.selected and list.selected.data

    list.selected = list.children[1]

    if target then
        for _, item in ipairs(list.children) do
            if item == target or item.data == target then
                list.selected = item

                break
            end
        end
    end

    if list.selected and list.selected.data ~= previousSelection then
        list.selected:onClick(nil, nil, 1)
    end
end

local function filterList(list, search)
    local unfilteredItems = list.unfilteredItems
    local previousSelection = list.selected and list.selected.data
    local newSelection = nil
    local filteredItems = filterItems(unfilteredItems, search)

    list.children = {}

    for _, item in ipairs(filteredItems) do
        if item.data == previousSelection then
            newSelection = item
        end

        list:addChild(item)
    end

    ui.runLate(function()
        setSelection(list, newSelection)
    end)
end

local function searchFieldChanged(element, new, old)
    local list = element.list

    filterList(list, new)
end

function filteredList.getFilteredList(callback, items, initialSearch, initialItem)
    items = items or {}
    initialSearch = initialSearch or ""
    initialItem = initialItem or nil

    local filteredItems = filterItems(items, initialSearch)

    local list = uiElements.list(filteredItems, callback):with(uiUtils.hook({
        layoutLateLazy = layoutWidthUpdate
    })):with({
        unfilteredItems = items
    })

    ui.runLate(function()
        setSelection(list, initialItem)
    end)

    local scrolledList = uiElements.scrollbox(list):with(uiUtils.hook({
        calcWidth = calculateWidth,
        layoutLateLazy = layoutWidthUpdate
    })):with(uiUtils.fillHeight(true))

    local searchField = uiElements.field(initialSearch, searchFieldChanged):with({
        list = list
    }):with(uiUtils.fillWidth)

    local column = uiElements.column({
        searchField,
        scrolledList
    }):with(uiUtils.fillHeight(true))

    return column, list, searchField
end

return filteredList