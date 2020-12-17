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
-- TODO - Implement nodes
function triggers.getSelection(room, entity)
    local name = entity._name
    local handler = triggers.registeredtriggers[name]

    if handler.selection then
        return handler.selection(room, entity)

    elseif handler.rectangle then
        return handler.rectangle(room, entity), nil

    else
        local drawable = triggers.getDrawable(name, handler, room, entity)

        if drawable.getRectangle then
            return drawable:getRectangle(), nil
        end
    end
end

function triggers.moveSelection(room, layer, selection, x, y)

end

-- Returns all triggers of room
function triggers.getRoomItems(room, layer)
    return room.triggers
end


return triggers