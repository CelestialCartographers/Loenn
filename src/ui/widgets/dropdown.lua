-- Dropdown wrapper for our list implementation
-- Uses magic lists instead of normal lists, increasing performance for long lists

local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local lists = require("ui.widgets.lists")
local utils = require("utils")
local widgetUtils = require("ui.widgets.utils")

local dropdowns = {}

-- For styling
uiElements.add("magicDropdown", {
    style = {
        padding = 4,
        spacing = 0,
    }
})

local function closeDropdown(list)
    list.dropdownMenuVisible = false
    list.container:removeSelf()

    ui.runLate(function()
        widgetUtils.focusElement(list.options.spawnParent)
    end)
end

local function dataToElement(list, data, element)
    if not element then
        element = uiElements.listItem()

        element:hook({
            onClick = function(orig, self, x, y, button, isDrag, presses)
                orig(self, x, y, button, isDrag, presses)

                list.button:setText(element.text)
                list:setSelection(element.data)

                closeDropdown(list)
            end
        })
    end

    if data then
        element.text = data.text
        element.data = data.data
        element._parentProxy = list.options.parentProxy
    end

    return element
end

local function listUpdate(orig, self, dt)
    orig(self, dt)

    if self.dropdownMenuVisible and self.parent then
        local target = ui.focusing
        local focused = ui.focusing == self.options.spawnParent

        while target and not focused do
            if target == self or target == self.column then
                focused = true
            end

            target = target.parent
        end

        if not focused then
            closeDropdown(self)
        end
    end
end

function dropdowns.fromList(callback, stringOptions, options)
    options = options or {}
    options.dataToElement = options.dataToElement or dataToElement

    local listItems = {}

    for _, option in ipairs(stringOptions) do
        if type(option) == "string" then
            table.insert(listItems, {
                text = option,
                data = option
            })

        else
            table.insert(listItems, option)
        end
    end

    local listColumn, list = lists.getMagicList(callback, listItems, options)
    local listPanel = uiElements.panel({listColumn})
    local selectedIndex = options.initialItem or 1
    local selectedItem = listItems[selectedIndex]
    local initialText = selectedItem and selectedItem.text or ""

    local button = uiElements.button(initialText, function(self, x, y, button)
        if self.enabled and button == 1 then
            if self:shouldReveal() then
                self:revealDropdown(false)

            else
                self:closeDropdown()
            end
        end
    end)

    local dropdownStyle = uiElements.magicDropdown.__default.style or {}

    -- Panel handles the padding
    listColumn.style.padding = 0
    listColumn.style.spacing = 0

    listPanel.style.padding = dropdownStyle.padding
    listPanel.style.spacing = dropdownStyle.spacing


    list:hook({
        update = listUpdate
    })

    list.options = options
    list.options.spawnParent = options.spawnParent or button

    list.button = button
    list.container = listPanel
    list._parentProxy = options.parentProxy

    button.list = list
    button:addChild(uiElements.icon("ui:icons/drop"):with(uiUtils.at(0.999 + 1, 0.5 + 5)))
    button.submenuParent = button

    list.shownOnce = false

    function button.shouldReveal(self)
        local dropdownListVisible = not not list.container.parent
        local currentListItems = self.list._magicList and self.list.data or self.list.children
        local revealedWithEmptyList = self.list.openedFromFilter and #currentListItems == 0

        return not dropdownListVisible or revealedWithEmptyList
    end

    function button.closeDropdown(self)
        closeDropdown(self.list)
    end

    function button.revealDropdown(self, fromSearchFilter)
        local spawnParent = options.spawnParent or self
        local spawnRoot = options.spawnRoot or ui.root

        if self:shouldReveal() then
            local spawnX = spawnParent.screenX
            local spawnY = spawnParent.screenY + spawnParent.height

            if spawnParent.parent then
                spawnY += spawnParent.parent.style.spacing
            end

            -- Unfilter list if opened with the dedicated button
            if not fromSearchFilter then
                list:filter("", true)
            end

            spawnRoot:addChild(list.container)

            list.container.realX = -4096
            list.container.realY = -4096

            list:layout()

            -- Let layouting finish
            ui.runLate(function()
                ui.runLate(function()
                    -- List height didn't seem to make sense after two layout calls, this is good enough
                    local listHeight = lists.getMagicListHeight(list)
                    local listBottom = spawnY + listHeight
                    local rootBottom = spawnRoot.realY + spawnRoot.height

                    list.container.height = math.min(listHeight, spawnRoot.height)

                    if listBottom > rootBottom then
                        if fromSearchFilter then
                            list.height = rootBottom - spawnY
                            list.container.height = rootBottom - spawnY

                        else
                            local offsetY = listBottom - rootBottom

                            spawnY = math.max(spawnRoot.realY, spawnY - offsetY)
                        end
                    end

                    -- If the list has not been shown yet than running it later causes it to not be visible
                    -- Running it late fixes flickering of the scrollbar
                    if list.shownOnce then
                        ui.runLate(function()
                            list.container.realX = spawnX
                            list.container.realY = spawnY
                        end)

                    else
                        list.container.realX = spawnX
                        list.container.realY = spawnY
                        list.shownOnce = true
                    end
                end)
            end)

            list.dropdownMenuVisible = true
            list.openedFromFilter = fromSearchFilter
            list._parentProxy = options.parentProxy
        end
    end

    function button.setSelection(self, value, preventCallback)
        list:setSelection(value, preventCallback)

        local index = list._selectedIndex
        local item = listItems[index]
        local text = item and item.text or ""

        button:setText(text)
    end

    function button.filter(self, text, preventCallback)
        list:filter(text, preventCallback)
    end

    return button
end

return dropdowns