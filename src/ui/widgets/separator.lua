local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local lineSeparator = {}

-- For styling
uiElements.add("lineSeparator", {
    base = "group",

    style = {
        thickness = 3,
        radius = 3,
        color = {0.225, 0.225, 0.225, 1.0},
        padding = 0,
        spacing = 8
    }
})

local function lineDrawHook(orig, self)
    local separatorStyle = uiElements.lineSeparator.__default.style or {}
    local thickness = separatorStyle.thickness
    local radius = separatorStyle.radius
    local color = separatorStyle.color

    local parentHeight = self.parent.innerHeight
    local offsetY = math.floor((parentHeight - thickness) / 2)

    local pr, pg, pb, pa = love.graphics.getColor()

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", self.screenX, self.screenY + offsetY, self.width, thickness, radius, radius)
    love.graphics.setColor(pr, pg, pb, pa)
end

function lineSeparator.getLine(width)
    local line = uiElements.panel({}):hook({
        draw = lineDrawHook
    })

    if type(width) == "number" then
        line:hook({
            calcWidth = function(orig, self)
                return width
            end
        })

    elseif width then
        line:with(uiUtils.fillWidth(true))
    end

    return line
end

function lineSeparator.getSeparator(label, leftWidth, rightWidth)
    local separatorStyle = uiElements.lineSeparator.__default.style or {}

    if type(label) == "string" then
        label = uiElements.label(label)
    end

    local row = uiElements.row({})

    row.style.padding = separatorStyle.padding
    row.style.spacing = separatorStyle.spacing

    if leftWidth and leftWidth ~= 0 then
        row:addChild(lineSeparator.getLine(leftWidth))
    end

    if label then
        row:addChild(label)
    end

    if leftWidth == true or rightWidth == true then
        row:with(uiUtils.fillWidth(false))
    end

    if rightWidth and rightWidth ~= 0 then
        row:addChild(lineSeparator.getLine(rightWidth))
    end

    return row
end

return lineSeparator