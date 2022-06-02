local parallax = {}

local fieldOrder = {
    "texture", "only", "exclude", "tag",
    "flag", "notflag", "blendmode", "color",
    "x", "y", "scrollx", "scrolly",
    "speedx", "speedy", "fadex", "fadey",
    "alpha"
}

local defaultData = {
    x = 0.0,
    y = 0.0,

    scrollx = 1.0,
    scrolly = 1.0,
    speedx = 0.0,
    speedy = 0.0,

    alpha = 1.0,
    color = "FFFFFF",

    only = "*",
    exclude = "",

    texture = "",

    flipx = false,
    flipy = false,
    loopx = true,
    loopy = true,

    flag = "",
    notflag = "",

    blendmode = "alphablend",
    instantIn = false,
    instantOut = false,
    fadeIn = false,

    fadex = "",
    fadey = "",

    tag = ""
}

local fieldInformation = {
    color = {
        fieldType = "color"
    }
}

function parallax.defaultData(style)
    return defaultData
end

function parallax.fieldOrder(style)
    return fieldOrder
end

function parallax.fieldInformation(style)
    return fieldInformation
end

function parallax.languageData(language, style)
    return language.style.parallax
end

function parallax.displayName(language, style)
    local texture = style.texture

    return string.format("Parallax - %s", texture)
end

return parallax