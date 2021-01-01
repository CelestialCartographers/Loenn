local utils = require("utils")
local drawing = require("drawing")
local drawableFunction = require("structs.drawable_function")

local colors = require("colors")

local font = love.graphics.getFont()
local triggerFontSize = 1

local triggers = {}

-- TODO - Add trigger registration
triggers.registeredTriggers = {}

-- Returns drawable, depth
function triggers.getDrawable(name, handler, room, trigger, viewport)
    local func = function()
        local displayName = utils.humanizeVariableName(name)

        local x = trigger.x or 0
        local y = trigger.y or 0

        local width = trigger.width or 16
        local height = trigger.height or 16

        drawing.callKeepOriginalColor(function()
            love.graphics.setColor(colors.triggerColor)

            love.graphics.rectangle("line", x, y, width, height)
            love.graphics.rectangle("fill", x, y, width, height)

            love.graphics.setColor(colors.triggerTextColor)

            drawing.printCenteredText(displayName, x, y, width, height, font, triggerFontSize)
        end)
    end

    return drawableFunction.fromFunction(func), 0
end

-- Returns main trigger selection rectangle, then table of node rectangles
function triggers.getSelection(room, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    local mainRectangle = utils.rectangle(trigger.x, trigger.y, trigger.width, trigger.height)
    local nodeRectangles = {}

    local nodes = trigger.nodes

    if nodes then
        for i, node in ipairs(nodes) do
            local x, y = node[1], node[2]

            nodeRectangles[i] = utils.rectangle(x - 2, y - 2, 5, 5)
        end
    end

    return mainRectangle, nodeRectangles
end

function triggers.moveSelection(room, layer, selection, x, y)
    local trigger, node = selection.item, selection.node

    if node == 0 then
        trigger.x += x
        trigger.y += y

    else
        local nodes = trigger.nodes

        if nodes and node <= #nodes then
            nodes[node][1] += x
            nodes[node][2] += y
        end
    end

    selection.x += x
    selection.y += y

    return true
end

function triggers.deleteSelection(room, layer, selection)
    local targets = triggers.getRoomItems(room, layer)
    local target, node = selection.item, selection.node

    for i, decal in ipairs(targets) do
        if decal == target then
            if node == 0 then
                table.remove(targets, i)

            else
                local nodes = decal.nodes

                if nodes then
                    table.remove(nodes, node)
                end
            end

            return true
        end
    end

    return false
end

-- Returns all triggers of room
function triggers.getRoomItems(room, layer)
    return room.triggers
end

function triggers.canReisze(room, layer, item)
    return true, true
end

function triggers.minimumSize(room, layer, item)
    return 8, 8
end

return triggers