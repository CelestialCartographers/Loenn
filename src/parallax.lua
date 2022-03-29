local parallax = {}

local fieldOrder = {
    "texture", "only", "exclude", "tag",
    "flag", "notflag", "blendmode", "color",
    "x", "y", "scrollx", "scrolly",
    "speedx", "speedy", "fadex", "fadey",
    "alpha"
}

local fieldInformation = {
    color = {
        fieldType = "color"
    }
}

-- TODO - Default data

function parallax.fieldOrder(style)
    return fieldOrder
end

function parallax.fieldInformation(style)
    return fieldInformation
end

function parallax.languageData(language, style)
    return language.style.parallax
end

return parallax