local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")
local drawing = require("utils.drawing")

local collapsable = {}

local function getIndicatorText(options, state)
    local renderType = options.renderType

    if renderType == "text" then
        local collapsedText = options.collapsedText
        local uncollapsedText = options.uncollapsedText

        return state and collapsedText or uncollapsedText
    end

    return ""
end

local function collapsableIndicatorDrawDefault(widget, state)
    local scale = 0.75
    local width, height = widget.width, widget.height
    local longEdge = widget.width * scale
    local shortEdge = math.floor(longEdge / math.sqrt(2))
    local x, y = widget.screenX, widget.screenY
    local theta = state and -math.pi / 2 or 0

    local triangleOffsetX = 0
    local triangleOffsetY = 0

    if theta == 0 then
        triangleOffsetX = math.floor(height / 2)
        triangleOffsetY = math.floor(width / 2 + longEdge / 4)

    else
        triangleOffsetX = math.floor(width / 2 + longEdge / 4)
        triangleOffsetY = math.floor(height / 2)
    end

    drawing.triangle("fill", x + triangleOffsetX, y + triangleOffsetY, theta, shortEdge)
end

local function collapsableIndicatorDraw(self)
    local options = self.options
    local renderType = options.renderType

    if renderType == "text" then
        return uiElements.label.draw(self)
    end

    local drawFunction = options.drawFunction

    drawFunction(self, self.contentCollapsed, options)
end

local function collapsableIndicatorCollapsed(self, state)
    local options = self.options
    local renderType = options.renderType

    self.contentCollapsed = state

    if renderType == "text" then
        self.text = getIndicatorText(self.options, state)
    end

    self:reflow()
end

local function collapsableIndicatorCalcWidth(self)
    local renderType = self.options.renderType

    if renderType == "draw" then
        return uiElements.label.calcHeight(self)

    else
        return uiElements.label.calcWidth(self)
    end
end

function collapsable.getCollapsableIndicator(options)
    options.renderType = options.renderType or "draw"
    options.collapsedText = options.collapsedText or ">"
    options.uncollapsedText = options.uncollapsedText or "v"
    options.drawFunction = options.drawFunction or collapsableIndicatorDrawDefault
    options.indent = options.indent or 16

    local initialText = getIndicatorText(options, not options.startOpen)
    local indicator = uiElements.label(initialText):with({
        options = options,

        collapsed = collapsableIndicatorCollapsed,
        draw = collapsableIndicatorDraw,
        calcWidth = collapsableIndicatorCalcWidth
    })

    indicator:collapsed(not options.startOpen)

    return indicator
end

function collapsable.getCollapsable(text, content, options)
    options = options or {}

    local widget = uiElements.column()
    local headerCollapseIndicator = collapsable.getCollapsableIndicator(options)
    local headerLabel = uiElements.label(text)
    local header = uiElements.row({headerCollapseIndicator, headerLabel}):with({
        interactive = 1,
        contentCollapsed = not options.startOpen,
        onClick = function(self, x, y, button)
            -- Only allow left click
            if button ~= 1 then
                return
            end

            if self.contentCollapsed then
                widget:addChild(content)
                content.screenX = widget.screenX + options.indent

            else
                content:removeSelf()
            end

            self.contentCollapsed = not self.contentCollapsed

            headerCollapseIndicator:collapsed(self.contentCollapsed)

            self:reflow()
        end
    })

    widget:addChild(header)

    if options.startOpen then
        widget:addChild(content)
    end

    return widget
end

return collapsable