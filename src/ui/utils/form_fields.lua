local configs = require("configs")

local formFieldsUtils = {}

function formFieldsUtils.getMinMaxWidth(options)
    local uiScale = configs.ui.theme.uiScale or 1
    local minWidth = (options.minWidth or options.width or 160) * uiScale
    local maxWidth = (options.maxWidth or options.width or 160) * uiScale

    return minWidth, maxWidth
end

return formFieldsUtils