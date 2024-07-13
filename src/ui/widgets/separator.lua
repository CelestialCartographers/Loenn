local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")

local lineSeparator = {}

uiElements.add("horizontalLine", {
    style = {
        thickness = 3,
        radius = 3,
        color = {0.225, 0.225, 0.225, 1.0},
    },

    init = function(self, width)
        self._width = width

        if width == true then
            self:with(uiUtils.fillWidth(false))
        end
    end,

    calcWidth = function(self)
        return self._width
    end,

    calcHeight = function(self)
        return 1
    end,

    draw = function(self)
        local separatorStyle = self.style
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
})

-- For styling
uiElements.add("lineSeparator", {
    base = "row",

    style = {
        padding = {0, 0, 0, 4},
        spacing = 8,
        contentPadding = 8
    },

    init = function(self, label, leftWidth, rightWidth)
        uiElements.row.init(self, {})

        if type(label) == "string" then
            label = uiElements.label(label)
        end

        if leftWidth and leftWidth ~= 0 then
            self:addChild(uiElements.horizontalLine(leftWidth))
        end

        if label then
            self:addChild(label)
        end

        if rightWidth and rightWidth ~= 0 then
            self:addChild(uiElements.horizontalLine(rightWidth))
        end

        if leftWidth == true or rightWidth == true then
            self:with(uiUtils.fillWidth(false))
        end
    end,

    addBottomPadding = function(self, n)
        local padding = self.style.padding
        local paddingType = type(padding)

        n = n or self.style.contentPadding or 8

        if paddingType == "number" then
            self.style.padding = {padding, padding + n, padding, padding}

        elseif paddingType == "table" then
            local lp, tp, rp, bp = unpack(padding)

            self.style.padding = {lp, tp + n, rp, bp}
        end
    end
})

return uiElements.lineSeparator