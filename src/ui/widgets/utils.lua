local widgetUtils = {}

function widgetUtils.removeWindowTitlebar(window)
    return window:with(function(el)
        table.remove(el.children, 1).parent = el
    end)
end

return widgetUtils