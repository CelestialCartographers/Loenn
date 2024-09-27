local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local utils = require("utils")

local widgetUtils = {}

widgetUtils.defaultPadding = 16

function widgetUtils.removeWindowTitlebar(window)
    return window:with(function(el)
        table.remove(el.children, 1).parent = el
    end)
end

function widgetUtils.setWindowTitle(window, title)
    if window and window.titlebar and window.titlebar.label then
        window.titlebar.label.text = title
    end
end

function widgetUtils.addWindowCloseButton(window, callback)
    if window and window.titlebar then
        local titlebar = window.titlebar
        local labelFontHeight = window.titlebar.label.style.font:getHeight(" ")
        local closeButton = uiElements.buttonClose()

        closeButton:layout()

        if titlebar.height == -1 then
            titlebar:layout()
        end

        local padding = closeButton.style.padding
        local deltaHeight = titlebar.height - closeButton.height

        -- Adjust padding to match titlebar height
        closeButton.style.padding += math.floor(deltaHeight / 2)
        closeButton.cb = function()
            if callback then
                callback(window)

            else
                window:removeSelf()
            end
        end

        window._closeButton = closeButton

        table.insert(titlebar.children, closeButton)
    end
end

function widgetUtils.closeWindow(window)
    if window then
        if window._closeButton then
            return window._closeButton.cb()
        end

        window:removeSelf()
    end
end

function widgetUtils.getSimpleOverlayWidget(widget, ...)
    local widgetType = utils.typeof(widget)

    if widgetType == "string" then
        widget = uiElements.label(widget)

    elseif widgetType == "Image" then
        widget = uiElements.image(widget)

    elseif widgetType == "table" then
        if widget.image then
            -- Sprite metadata
            widget = uiElements.image(widget.image, widget.quad)

        elseif #widget > 0 then
            -- Colored text
            widget = uiElements.label(widget)
        end

    elseif widgetType == "function" then
        widget = widget(...)
    end

    -- Make sure the processed widget is a table
    if widget and utils.typeof(widget) ~= "table" then
        widget = {widget}
    end

    return widget
end

function widgetUtils.preventOutOfBoundsMovement(window, padding)
    padding = padding or widgetUtils.defaultPadding

    window:hook({
        update = function(orig, self)
            orig(self)

            if self._disableMovementClamping then
                return
            end

            local positionChanged = self.x ~= self._previousX or self.y ~= self._previousY
            local sizeChanged = self.width ~= self._previousWidth or self.height ~= self._previousHeight

            -- No need to run if position hasn't changed
            if positionChanged or sizeChanged then
                local usableWidth, usableHeight = widgetUtils.getUsableSize(padding)
                local newX, newY = self.x, self.y

                newX = math.max(math.min(usableWidth - window.width + padding, newX), padding)
                newY = math.max(math.min(usableHeight - window.height + padding, newY), padding)

                self.x = newX
                self.realX = newX
                self.y = newY
                self.realY = newY
            end

            self._previousX = self.x
            self._previousY = self.y
            self._previousWidth = self.width
            self._previousHeight = self.height

        end
    })
end

function widgetUtils.moveWindow(window, newX, newY, threshold, clamp, padding)
    padding = padding or widgetUtils.defaultPadding
    threshold = threshold or 4

    local usableWidth, usableHeight = widgetUtils.getUsableSize(padding)
    local currentX, currentY = window.x, window.y

    if clamp ~= false then
        newX = math.max(math.min(usableWidth - window.width + padding, newX), padding)
        newY = math.max(math.min(usableHeight - window.height + padding, newY), padding)
    end

    if math.abs(currentX - newX) > threshold or math.abs(currentY - newY) > threshold then
        window.x = newX
        window.realX = newX
        window.y = newY
        window.realY = newY

        if window.parent then
            window.parent:reflow()
        end

        ui.root:recollect(false, true)
    end
end

function widgetUtils.lerpWindowPosition(window, fromX, fromY, toX, toY, percent, threshold, padding)
    padding = padding or widgetUtils.defaultPadding
    threshold = threshold or 4

    local newX, newY = math.floor(fromX + (toX - fromX) * percent), math.floor(fromY + (toY - fromY) * percent)

    widgetUtils.moveWindow(window, newX, newY, threshold, false, padding)
end

-- The max usable size to not overlap with menubar and have some side padding
function widgetUtils.getUsableSize(padding)
    padding = padding or widgetUtils.defaultPadding

    local root = ui.root.children[1]
    local windowGroup = root._windowGroup

    return windowGroup.width - padding * 2, windowGroup.height - padding * 2
end

-- Based on OlympUI fillHeight
-- Very naive, meant for very simple windows with scrollboxes (like forms)
function widgetUtils.fillHeightIfNeeded(minHeight, maxHeight)
    local function apply(el)
        uiUtils.hook(el, {
            layoutLazy = function(orig, self)
                -- Required to allow the container to shrink again.
                orig(self)

                self.height = 0
            end,

            layoutLateLazy = function(orig, self)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
                self:repaint()
            end,

            layoutLate = function(orig, self)
                if not maxHeight then
                    local _, usableHeight = widgetUtils.getUsableSize()

                    maxHeight = usableHeight
                end

                local spacing = self.parent.style:get("spacing") or 0
                local height = 0

                -- Titlebar check
                if el.titlebar then
                    height += el.titlebar.height + spacing
                end

                local inner = el.inner
                local innerSpacing = inner.style:get("spacing") or 0
                local innerPadding = inner.style:get("padding") or 0

                height += innerPadding * 2

                for i, child in ipairs(inner.children) do
                    local childType = child.__type

                    if childType == "scrollbox" then
                        height += child.inner.height

                    else
                        height += child.height
                    end

                    if i ~= #inner.children then
                        height += innerSpacing
                    end
                end

                height = math.max(math.min(math.floor(height), maxHeight or self.parent.innerHeight), minHeight or 0)
                self.height = height
                self.innerHeight = height - (self.style:get("padding") or 0) * 2

                orig(self)
            end
        })
    end

    return apply
end

function widgetUtils.focusMainEditor()
    ui.interactiveIterate(ui.focusing, "onUnfocus")
    ui.focusing = false
end

function widgetUtils.cursorDeltaFromElementCenter(element, x, y)
    local elementX, elementY = element.screenX, element.screenY
    local elementWidth, elementHeight = element.width, element.height

    return x - elementX - elementWidth / 2, y - elementY - elementHeight / 2
end

function widgetUtils.centerWindow(window, parent)
    parent = parent or ui.root

    local x = math.floor((parent.width - window.width) / 2)
    local y = math.floor((parent.height - window.height) / 2)

    widgetUtils.moveWindow(window, x, y, 0, 0, 0)
end

-- Focus element and do any extra logic to prevent them from crashing
function widgetUtils.focusElement(element)
    ui.focusing = element

    if utils.typeof(element) == "field" then
        element.blinkTime = 0
        element.__wasKeyRepeat = love.keyboard.hasKeyRepeat()
    end
end

function widgetUtils.updateHoveredTarget()
    ui.mousemoved(0, 0)
end

return widgetUtils
