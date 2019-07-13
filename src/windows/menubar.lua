local state = require("loaded_state")
local viewportHandler = require("viewport_handler")
local utils = require("utils")

local menubar = {}

-- TODO - Use numerical indices for order
local menubarItems = {
    ["File"] = {
        ["New"] = function() print("New") end,
        ["Save"] = function() print("Save") end,
        ["Save As"] = function() print("Save As") end,
    },
    ["Test"] = {
        ["Foo"] = function() print("Foo") end,
        ["Bar"] = function() print("Bar") end,
        ["Baz"] = function() print("Baz") end,
        ["Bax"] = {
            ["Foo"] = function() print("Foo2") end,
            ["Bar"] = function() print("Bar2") end,
        }
    },
    ["a"] = {
        ["b"] = {
            ["c"] = {
                ["a"] = function() print("a") end,
                ["b"] = function() print("b") end,
                ["c"] = function() print("c") end,
            },
            ["d"] = {
                ["a"] = function() print("a") end,
                ["b"] = function() print("b") end,
                ["c"] = function() print("c") end,
            }
        }
    }
}

local editModeActiveFlags = {"movable", "scrollbar", "scalable", "border", "title"}
local editModeInactiveFlags = {"scrollbar"}

menubar.x = 0
menubar.y = 0
menubar.width = viewportHandler.viewport.width
menubar.height = 50

menubar.name = "Menubar"

function countSubMenus(tree)
    local count = 0

    for k, v <- tree do
        if type(v) == "table" then
            count += 1
        end
    end

    return count
end

function makeMenubar(ui, tree, top)
    local top = top == nil
    local keys = countSubMenus(tree)
    ui:layoutRow('dynamic', 30, top and keys or 1)
    
    for name, data <- tree do
        if type(data) == "table" then
            if ui:menuBegin(name, nil, 120, 200) then
                print(name)

                makeMenubar(ui, data, false)
                ui:menuEnd()
            end

        else
            if ui:menuItem(name) then
                data()
            end
        end
    end
end

function menubar.init(ui)
   
end

function menubar.update(ui)
    -- TODO - Add maploaded event

    local flags = editModeActiveFlags
    
    if ui:windowBegin(menubar.name, menubar.x, menubar.y, menubar.width, menubar.height, unpack(flags)) then
        --ui:layoutRow('dynamic', 30, 2)
        makeMenubar(ui, menubarItems)
        --print("---")

	    ui:windowEnd()
    end
end

return menubar
