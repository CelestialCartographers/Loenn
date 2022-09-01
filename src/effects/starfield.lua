local starfield = {}

starfield.name = "starfield"
starfield.fieldInformation = {
    color = {
        fieldType = "color",
        allowEmpty = true
    }
}
starfield.defaultData = {
    color = "",
    scrollx = 1.0,
    scrolly = 1.0,
    speed = 1.0
}

return starfield