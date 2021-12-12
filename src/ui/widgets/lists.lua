local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local listWidgets = {}

local function calculateWidth(orig, element)
    return element.inner.width
end

local function filterItems(items, search, caseSensitive)
    local filtered = {}

    if caseSensitive ~= false then
        search = search:lower()
    end

    for _, item in ipairs(items) do
        local text = item.text

        if caseSensitive ~= false then
            text = text:lower()
        end

        if text:contains(search) then
            table.insert(filtered, item)
        end
    end

    return filtered
end

function listWidgets.setSelection(list, target, preventCallback, callbackRequiresChange)
    -- Select first item as default, callback if it exists
    -- If target is defined attempt to select this instead of the first item

    local selectedTarget = false
    local selectedIndex = 1
    local previousSelection = list.selected and list.selected.data
    local newSelection

    if target and target ~= false then
        for i, item in ipairs(list.children) do
            if item == target or item.data == target or item.text == target or i == target then
                newSelection = item
                selectedTarget = true
                selectedIndex = i

                break
            end
        end
    end

    if newSelection then
        list.selected = newSelection

        if not preventCallback then
            local dataChanged = newSelection.data ~= previousSelection

            if callbackRequiresChange and dataChanged or not callbackRequiresChange then
                -- Set owner manually here for now
                -- TODO - Test whether this is actually needed later
                list.selected.owner = list
                list.selected:onClick(nil, nil, 1)
            end
        end
    end

    return selectedTarget, selectedIndex
end

function listWidgets.updateItems(list, items, target, fromFilter, preventCallback, callbackRequiresChange)
    local previousSelection = list.selected and list.selected.data
    local newSelection

    local processedItems = items

    if not fromFilter and list.searchField then
        local search = list.searchField:getText() or ""

        processedItems = filterItems(items, search)
    end

    for _, item in ipairs(processedItems) do
        if item.data == previousSelection then
            newSelection = item
        end

        if fromFilter then
            item:reflow()
        end
    end

    list.children = processedItems

    ui.runLate(function()
        listWidgets.setSelection(list, target or newSelection, preventCallback, callbackRequiresChange)
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

    listWidgets.updateItems(list, filteredItems, nil, true, false, true)
end

local function getSearchFieldChanged(onChange)
    return function(element, new, old)
        if onChange then
            onChange(element, new, old)
        end

        filterList(element.list, new)
    end
end

function listWidgets.setFilterText(list, text, updateList)
    local searchField = list.searchField

    if searchField then
        searchField:setText(text)

        if updateList or updateList == nil then
            filterList(list, text)
        end
    end
end

local function getColumnForList(searchField, scrolledList, mode)
    local columnItems

    if mode == "below" then
        columnItems = {
            scrolledList,
            searchField:with(uiUtils.bottombound)
        }

    elseif mode == "above" then
        columnItems = {
            searchField,
            scrolledList
        }

    else
        columnItems = {scrolledList}
    end

    return uiElements.column(columnItems):with(uiUtils.fillHeight(false))
end

function listWidgets.getList(callback, items, options)
    options = options or {}
    items = items or {}

    local initialSearch = options.initialSearch or ""
    local filteredItems = filterItems(items, initialSearch)

    local list = uiElements.list(filteredItems, callback):with({
        unfilteredItems = items,
        minWidth = options.minimumWidth or 128
    })

    ui.runLate(function()
        listWidgets.setSelection(list, list.options.initialItem)
    end)

    local scrolledList = uiElements.scrollbox(list):with(uiUtils.hook({
        calcWidth = calculateWidth
    })):with(uiUtils.fillHeight(true))

    local searchFieldCallback = getSearchFieldChanged(options.searchBarCallback)
    local searchField = uiElements.field(initialSearch, searchFieldCallback):with({
        list = list
    }):with(uiUtils.fillWidth)

    list.options = options
    list.searchField = searchField

    local column = getColumnForList(searchField, scrolledList, options.searchBarLocation)

    return column, list, searchField
end

return listWidgets