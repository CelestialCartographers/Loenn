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
    local minimumNodes, maximumNodes = triggers.nodeLimits(room, layer, target)

    for i, trigger in ipairs(targets) do
        if trigger == target then
            local nodes = trigger.nodes

            -- Delete trigger if deleting a node gives it too few nodes
            -- Set node to 0 to move deletion target from node to trigger itself
            if nodes and node > 0 then
                local nodeCount = #nodes

                if minimumNodes and minimumNodes ~= -1 and nodeCount - 1 < minimumNodes then
                    node = 0
                end
            end
            if node == 0 then
                table.remove(targets, i)

            else
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

function triggers.canResize(room, layer, trigger)
    return true, true
end

function triggers.minimumSize(room, layer, trigger)
    return 8, 8
end

function triggers.nodeLimits(room, layer, trigger)
    local name = trigger._name
    local handler = triggers.registeredTriggers[name]

    if handler.nodeLimits then
        return handler.nodeLimits(room, trigger)

    else
        return 0, 0
    end
end

return triggers