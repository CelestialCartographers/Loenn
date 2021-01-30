local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local listWidgets = {}

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

function listWidgets.setSelection(list, target, preventCallback, callbackRequiresChange)
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

    if list.selected and not preventCallback then
        local dataChanged = list.selected.data ~= previousSelection

        if callbackRequiresChange and dataChanged or not callbackRequiresChange then
            -- Set owner manually here for now
            -- TODO - Test whether this is actually needed later
            list.selected.owner = list
            list.selected:onClick(nil, nil, 1)
        end
    end
end

function listWidgets.updateItems(list, items, fromFilter)
    local previousSelection = list.selected and list.selected.data
    local newSelection = nil

    for _, item in ipairs(items) do
        if item.data == previousSelection then
            newSelection = item
        end

        if fromFilter then
            item:reflow()
        end
    end

    list.children = items

    ui.runLate(function()
        listWidgets.setSelection(list, newSelection)
    end)

    list:reflow()
    ui.root:recollect()

    if not fromFilter then
        list.unfilteredItems = items
    end
end

local function filterList(list, search)
    local unfilteredItems = list.unfilteredItems
    local filteredItems = filterItems(unfilteredItems, search)

    listWidgets.updateItems(list, filteredItems, true, true)
end

local function searchFieldChanged(element, new, old)
    local list = element.list

    filterList(list, new)
end

function listWidgets.getFilteredList(callback, items, initialSearch, initialItem)
    items = items or {}
    initialSearch = initialSearch or ""

    local filteredItems = filterItems(items, initialSearch)

    local list = uiElements.list(filteredItems, callback):with(uiUtils.hook({
        layoutLateLazy = layoutWidthUpdate
    })):with({
        unfilteredItems = items
    })

    ui.runLate(function()
        listWidgets.setSelection(list, initialItem)
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
    })

    return column, list, searchField
end

function listWidgets.getList(callback, items, initialItem)
    local list = uiElements.list(items, callback):with(uiUtils.hook({
        layoutLateLazy = layoutWidthUpdate
    }))

    ui.runLate(function()
        listWidgets.setSelection(list, initialItem)
    end)

    local scrolledList = uiElements.scrollbox(list):with(uiUtils.hook({
        calcWidth = calculateWidth,
        layoutLateLazy = layoutWidthUpdate
    })):with(uiUtils.fillHeight(false))

    return scrolledList, list
end

return listWidgets