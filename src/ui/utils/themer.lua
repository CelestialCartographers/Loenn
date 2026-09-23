local ui, uiUtils, uiElements = require("ui").quick()
local utils = require("utils")

local configs = require("configs")

local themer = {}

local affectedByScale = {
    spacing = true,
    padding = true,
    margin = true,
    contentPadding = true,
    radius = true,
    thickness = true,
}

function themer.dump()
    local theme = {}

    for id, el in pairs(uiElements) do
        if utils.startsWith(id, "__") then
            local style = el.__default
            style = style and style.style

            if not style then
                style = {}
            end

            local sub = {}

            for key, value in pairs(style) do
                sub[key] = value
            end

            if sub then
                theme[id] = sub
            end
        end
    end

    return theme
end

function themer.apply(theme, scale)
    if not theme then
        return
    end

    scale = configs.ui.theme.uiScale or 1

    themer.applyElementStyles(theme)
    themer.applyFontInfo(theme, scale)
    themer.applyStyleScale(scale)
end

function themer.applyFontInfo(theme, scale)
    local defaultFontSize = configs.ui.theme.defaultFontSize or 12
    local labelFontSizeFallback = math.floor(defaultFontSize * scale)
    local labelFontSize = theme.labelFontSize or labelFontSizeFallback
    local labelFilename = theme.labelFilename
    local labelFont = theme.labelFont

    if not labelFont then
        if labelFilename then
            labelFont = love.graphics.newFont(labelFilename, labelFontSize)

        else
            labelFont = love.graphics.newFont(labelFontSize)
        end
    end

    if labelFont then
        uiElements.__label.__default.style.font = labelFont
    end
end

function themer.applyElementStyles(theme)
    if themer.current ~= themer.default and theme ~= themer.default then
        themer.applyElementStyles(themer.default)
    end

    themer.current = theme

    for id, tel in pairs(theme) do
        local el = uiElements[id]
        local style = el and el.__default

        if el and style then
            style = style and style.style

            if not style then
                style = {}
                el.__default.style = style
            end

            for key, value in pairs(tel) do
                style[key] = value
            end
        end
    end

    if ui.root then
        ui.globalReflowID = ui.globalReflowID + 1
    end
end

-- Naively apply the scale to all default styles according to affectedByScale
function themer.applyStyleScale(scale)
    -- Nothing to do
    if not scale or scale == 1 then
        return
    end

    for id, element in pairs(uiElements) do
        if utils.startsWith(id, "__") then
            local style = element and element.__default and element.__default.style

            if style then
                for key, value in pairs(style) do
                    if affectedByScale[key] then
                        if type(value) == "number" then
                            style[key] = math.floor(value * scale)

                        elseif type(value) == "table" then
                            for i, v in ipairs(value) do
                                style[key][i] = math.floor(v * scale)
                            end
                        end
                    end
                end
            end
        end
    end
end

function themer.skin(theme, deep, element)
    theme = theme or themer.default

    local function skin(el)
        local style = el.style
        local types = el.__types

        local custom = {}

        for key, value in pairs(style) do
            custom[key] = value
        end

        for i = #types, 1, -1 do
            local elementType = types[i]
            local elementBase = uiElements[elementType]
            local elementTheme = theme[elementType]

            if elementBase then
                elementBase = elementBase.__default.style

                if elementBase then
                    for key, value in pairs(elementBase) do
                        if type(value) == "table" then
                            local copy = {}

                            for k, v in pairs(value) do
                                copy[k] = v
                            end

                            value = copy
                        end

                        style[key] = value
                    end
                end
            end

            if elementTheme then
                for key, value in pairs(elementTheme) do
                    if type(value) == "table" then
                        local copy = {}

                        for k, v in pairs(value) do
                            copy[k] = v
                        end

                        value = copy
                    end

                    style[key] = value
                end
            end
        end

        for key, value in pairs(custom) do
            style[key] = value
        end

        if deep then
            local children = el.children

            if children then
                for i = 1, #children do
                    skin(children[i])
                end
            end
        end
    end

    if element then
        return skin(element)
    end

    if element == nil and type(deep) == "table" then
        return skin(deep)
    end

    if deep == nil then
        deep = true
    end

    return skin
end

themer.default = themer.dump()
themer.current = themer.default

return themer