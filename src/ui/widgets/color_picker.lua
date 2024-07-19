local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local utils = require("utils")
local formHelper = require("ui.forms.form")
local languageRegistry = require("language_registry")

local colorPicker = {}

local pickerAreaMinimumSize = 200
local sliderMinimumWidth = 24
local hsvFieldDecimals = 2

local valueRanges = {
    r = {0, 255},
    g = {0, 255},
    b = {0, 255},
    h = {0, 360},
    s = {0, 100},
    v = {0, 100},
    alpha = {0, 255}
}

local fieldTypes = {
    r = "integer",
    g = "integer",
    b = "integer",
    h = "number",
    s = "number",
    v = "number",
    hexColor = "hex_color",
    alpha = "integer",
}

local areaHSVPixelCode = [===[
    uniform float hue;

    vec3 hsv_to_rgb(float h, float s, float v) {
        return mix(vec3(1.0), clamp((abs(fract(h + vec3(3.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0), 0.0, 1.0), s) * v;
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        vec3 rgb = hsv_to_rgb(hue, texture_coords[0], 1 - texture_coords[1]);

        return vec4(rgb[0], rgb[1], rgb[2], 1.0) * color;
    }
]===]

local alphaPixelCode = [===[
    uniform float hue;
    uniform float saturation;
    uniform float value;

    uniform float width;
    uniform float height;

    float checkerSize = 4;

    vec4 whiteChecker = vec4(1.0, 1.0, 1.0, 1.0);
    vec4 darkChecker = vec4(0.5, 0.5, 0.5, 1.0);

    vec3 hsv_to_rgb(float h, float s, float v) {
        return mix(vec3(1.0), clamp((abs(fract(h + vec3(3.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0), 0.0, 1.0), s) * v;
    }

    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
    {
        float x = width * texture_coords[0];
        float y = height * texture_coords[1];

        float colorIndex = mod(floor(x / checkerSize) + floor(y / checkerSize), 2.0);
        vec4 checkerColor = colorIndex == 0 ? whiteChecker : darkChecker;

        vec3 selectedColor = hsv_to_rgb(hue, saturation, value);
        vec4 selectedColorAlpha = vec4(selectedColor[0], selectedColor[1], selectedColor[2], 1);

        return mix(checkerColor, selectedColorAlpha, texture_coords[0]);
    }
]===]

local areaHSVShader = love.graphics.newShader(areaHSVPixelCode)
local alphaShader = love.graphics.newShader(alphaPixelCode)

local function updateShaderHSV(hue, saturation, value)
    areaHSVShader:send("hue", hue)

    alphaShader:send("hue", hue)
    alphaShader:send("saturation", saturation)
    alphaShader:send("value", value)
end

local function getColorPickerArea(h, s, v, width, height)
    local canvas = love.graphics.newCanvas(width, height)

    updateShaderHSV(h, s, v)

    return canvas
end


local function getColorPickerSlider(h, s, v, width, height)
    local canvas = love.graphics.newCanvas(width, height)
    local imageData = canvas:newImageData()

    imageData:mapPixel(function(x, y, r, g, b, a)
        local hue = x / (width - 1)
        local cr, cg, cb = utils.hsvToRgb(hue, 1, 1)

        return cr, cg, cb, 1
    end, 0, 0, width, height)

    local image = love.graphics.newImage(imageData)

    return image, imageData
end

local function getAlphaSlider(h, s, v, width, height)
    local canvas = love.graphics.newCanvas(width, height)

    updateShaderHSV(h, s, v)

    alphaShader:send("width", width)
    alphaShader:send("height", height)

    return canvas
end

local function areaInteraction(interactionData)
    return function(widget, x, y)
        local areaSize = interactionData.areaSize
        local formFields = interactionData.formFields

        local innerX = utils.clamp(x - widget.screenX, 0, areaSize)
        local innerY = utils.clamp(y - widget.screenY, 0, areaSize)

        local saturation = innerX / areaSize
        local value = 1 - (innerY / areaSize)
        local data = formHelper.getFormData(formFields)

        data.s = utils.round(saturation * 100, hsvFieldDecimals)
        data.v = utils.round(value * 100, hsvFieldDecimals)
        interactionData.forceFieldUpdate = true

        formHelper.setFormData(formFields, data)
    end
end

local function sliderInteraction(interactionData)
    return function(widget, x, y)
        local areaSize = interactionData.areaSize
        local formFields = interactionData.formFields

        local innerX = utils.clamp(x - widget.screenX, 0, areaSize)
        local hue = innerX / areaSize
        local data = formHelper.getFormData(formFields)

        data.h = utils.round(hue * 360, hsvFieldDecimals)
        interactionData.forceFieldUpdate = true

        updateShaderHSV(hue, data.s / 100, data.v / 100)
        formHelper.setFormData(formFields, data)
    end
end

local function alphaInteraction(interactionData)
    return function(widget, x, y)
        local areaSize = interactionData.areaSize
        local formFields = interactionData.formFields

        local innerX = utils.clamp(x - widget.screenX, 0, areaSize)
        local percent = innerX / areaSize
        local data = formHelper.getFormData(formFields)

        data.alpha = utils.round(percent * 255)
        interactionData.forceFieldUpdate = true

        formHelper.setFormData(formFields, data)
    end
end

local function getFormFieldOrder(options)
    local fieldOrder = {}

    if options.showRGB ~= false then
        table.insert(fieldOrder, "r")
        table.insert(fieldOrder, "g")
        table.insert(fieldOrder, "b")
    end

    if options.showHex ~= false then
        table.insert(fieldOrder, "hexColor")
    end

    if options.showHSV ~= false then
        table.insert(fieldOrder, "h")
        table.insert(fieldOrder, "s")
        table.insert(fieldOrder, "v")
    end

    if options.showAlpha then
        table.insert(fieldOrder, "alpha")
    end

    return fieldOrder
end

local function findChangedColorGroup(current, previous)
    if current.r ~= previous.r or current.g ~= previous.g or current.b ~= previous.b then
        return "rgb"

    elseif current.h ~= previous.h or current.s ~= previous.s or current.v ~= previous.v then
        return "hsv"

    elseif current.hexColor ~= previous.hexColor then
        return "hex"

    elseif current.alpha ~= previous.alpha then
        return "alpha"
    end
end

-- RGB normalized
local function updateHsvFields(data, r, g, b)
    local h, s, v = utils.rgbToHsv(r, g, b)

    data.h = utils.round(h * 360, hsvFieldDecimals)
    data.s = utils.round(s * 100, hsvFieldDecimals)
    data.v = utils.round(v * 100, hsvFieldDecimals)
end

-- HSV Normalized
local function updateRgbFields(data, h, s, v)
    local r, g, b = utils.hsvToRgb(h, s, v)

    data.r = utils.round(r * 255)
    data.g = utils.round(g * 255)
    data.b = utils.round(b * 255)
end

-- RGB(A) normalized
local function updateHexField(data, r, g, b, a)
    -- Make sure we have alpha from data rather than argument
    -- Argument has fallback
    if data.alpha then
        data.hexColor = utils.rgbaToHex(r, g, b, a)

    else
        data.hexColor = utils.rgbToHex(r, g, b)
    end
end

local function updateFields(data, changedGroup, interactionData)
    local callback = interactionData.callback

    -- Change group here to make logic simpler
    if changedGroup == "hex" then
        local parsed, r, g, b = utils.parseHexColor(data.hexColor)

        updateHsvFields(data, r, g, b)

        changedGroup = "hsv"
    end

    if changedGroup == "rgb" then
        local r, g, b = (data.r or 0) / 255, (data.g or 0) / 255, (data.b or 0) / 255
        local alpha = (data.alpha or 0) / 255

        updateHsvFields(data, r, g, b)
        updateHexField(data, r, g, b, alpha)

    elseif changedGroup == "hsv" then
        local h, s, v = (data.h or 0) / 360, (data.s or 0) / 100, (data.v or 0) / 100
        updateRgbFields(data, h, s, v)

        local r, g, b = data.r / 255, data.g / 255, data.b / 255
        local alpha = (data.alpha or 0) / 255
        updateHexField(data, r, g, b, alpha)

    elseif changedGroup == "alpha" then
        local r, g, b = (data.r or 0) / 255, (data.g or 0) / 255, (data.b or 0) / 255
        local alpha = (data.alpha or 0) / 255

        updateHexField(data, r, g, b, alpha)
    end

    updateShaderHSV((data.h or 0) / 360, (data.s or 0) / 100, (data.v or 0) / 100)

    if callback then
        callback(data)
    end

    return data
end

local function fieldUpdater(interactionData)
    return function()
        local formFields = interactionData.formFields

        if interactionData.forceFieldUpdate or formHelper.formValid(formFields) then
            local formData = formHelper.getFormData(formFields)
            local changedGroup = findChangedColorGroup(formData, interactionData.previousFormData or formData)

            if changedGroup then
                local data = updateFields(formData, changedGroup, interactionData)

                formHelper.setFormData(formFields, data)
            end

            interactionData.previousFormData = formData
            interactionData.forceFieldUpdate = false
        end
    end
end

local function areaDrawing(interactionData)
    return function(orig, widget)
        local previousShader = love.graphics.getShader()

        love.graphics.setShader(areaHSVShader)
        orig(widget)
        love.graphics.setShader(previousShader)

        local formData = formHelper.getFormData(interactionData.formFields)
        local areaSize = interactionData.areaSize
        local x = utils.round((formData.s or 0) / 100 * areaSize)
        local y = utils.round((1 - (formData.v or 0) / 100) * areaSize)
        local widgetX, widgetY = widget.screenX, widget.screenY
        local rightX = widgetX + x
        local bottomY = widgetY + y
        local width, height = widget.width, widget.height

        local pr, pg, pb, pa = love.graphics.getColor()
        local previousLineWidth = love.graphics.getLineWidth()

        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", widgetX, bottomY - 1, width, 3)
        love.graphics.rectangle("fill", rightX - 1, widgetY, 3, height)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", widgetX + 1, bottomY, width - 2, 1)
        love.graphics.rectangle("fill", rightX, widgetY + 1, 1, height - 2)
        love.graphics.setLineWidth(previousLineWidth)
        love.graphics.setColor(pr, pg, pb, pa)
    end
end

local function sliderDrawIndication(interactionData)
    return function(orig, widget)
        orig(widget)

        local formData = formHelper.getFormData(interactionData.formFields)
        local areaSize = interactionData.areaSize
        local sliderWidth = interactionData.sliderWidth
        local x = utils.round((formData.h or 0) / 360 * areaSize)
        local widgetX, widgetY = widget.screenX, widget.screenY
        local sliderX = widgetX + x
        local pr, pg, pb, pa = love.graphics.getColor()
        local previousLineWidth = love.graphics.getLineWidth()

        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", sliderX - 1, widgetY, 3, sliderWidth)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", sliderX, widgetY + 1, 1, sliderWidth - 2)
        love.graphics.setLineWidth(previousLineWidth)
        love.graphics.setColor(pr, pg, pb, pa)
    end
end

local function alphaDrawIndication(interactionData)
    return function(orig, widget)
        local previousShader = love.graphics.getShader()

        love.graphics.setShader(alphaShader)
        orig(widget)
        love.graphics.setShader(previousShader)

        local formData = formHelper.getFormData(interactionData.formFields)
        local areaSize = interactionData.areaSize
        local sliderWidth = interactionData.sliderWidth
        local x = utils.round((formData.alpha or 0) / 255 * areaSize)
        local widgetX, widgetY = widget.screenX, widget.screenY
        local sliderX = widgetX + x
        local pr, pg, pb, pa = love.graphics.getColor()
        local previousLineWidth = love.graphics.getLineWidth()

        love.graphics.setLineWidth(1)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", sliderX - 1, widgetY, 3, sliderWidth)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", sliderX, widgetY + 1, 1, sliderWidth - 2)
        love.graphics.setLineWidth(previousLineWidth)
        love.graphics.setColor(pr, pg, pb, pa)
    end
end

function colorPicker.getColorPicker(hexColor, options)
    options = options or {}

    local language = languageRegistry.getLanguage()
    local callback = options.callback or function() end

    local parsed, r, g, b, a = utils.parseHexColor(hexColor)
    local h, s, v = utils.rgbToHsv(r or 0, g or 0, b or 0)

    local fieldOrder = getFormFieldOrder(options)
    local formData = {
        r = (r or 0) * 255,
        g = (g or 0) * 255,
        b = (b or 0) * 255,
        h = utils.round(h * 360, hsvFieldDecimals),
        s = utils.round(s * 100, hsvFieldDecimals),
        v = utils.round(v * 100, hsvFieldDecimals),
        hexColor = hexColor
    }

    if options.showAlpha then
        formData.alpha = (a or 1) * 255
    end

    local formOptions = {
        columns = 2,
        fieldOrder = fieldOrder,
        hideUnordered = true,
        fields = {}
    }

    for name, _ in pairs(formData) do
        local field = formOptions.fields[name] or {}
        local ranges = valueRanges[name]

        field.fieldType = fieldTypes[name]
        field.displayName = tostring(language.ui.colorPicker.fieldTypes.name[name])
        field.tooltipText = tostring(language.ui.colorPicker.fieldTypes.description[name])
        field.width = 80

        if ranges then
            field.minimumValue = ranges[1]
            field.maximumValue = ranges[2]
        end

        formOptions.fields[name] = field
    end

    local formBody, formFields = formHelper.getFormBody(formData, formOptions)

    -- Form body height is not properly calculated at this point
    -- This approximation seems to be accurate enough
    local areaSize = options.areaSize or math.max(formBody.height * #fieldOrder * 6 / 7, pickerAreaMinimumSize)
    local sliderWidth = options.sliderWidth or sliderMinimumWidth

    local areaCanvas = getColorPickerArea(h, s, v, areaSize, areaSize)
    local alphaCanvas = getAlphaSlider(h, s, v, areaSize, sliderWidth)
    local sliderImage, sliderImageData = getColorPickerSlider(h, s, v, areaSize, sliderWidth)

    local interactionData = {
        areaCanvas = areaCanvas,
        sliderImage = sliderImage,
        sliderImageData = sliderImageData,
        alphaCanvas = alphaCanvas,
        formFields = formFields,
        areaSize = areaSize,
        sliderWidth = sliderWidth,
        callback = callback,
        forceFieldUpdate = true
    }

    local areaElement = uiElements.image(areaCanvas):with({
        interactive = 1,
        onDrag = areaInteraction(interactionData),
        onClick = areaInteraction(interactionData)
    }):hook({
        draw = areaDrawing(interactionData)
    })
    local sliderElement = uiElements.image(sliderImage):with({
        interactive = 1,
        onDrag = sliderInteraction(interactionData),
        onClick = sliderInteraction(interactionData)
    }):hook({
        draw = sliderDrawIndication(interactionData)
    })
    local alphaElement = uiElements.image(alphaCanvas):with({
        interactive = 1,
        onDrag = alphaInteraction(interactionData),
        onClick = alphaInteraction(interactionData)
    }):hook({
        draw = alphaDrawIndication(interactionData)
    })

    local interactibleRows = {
        areaElement,
        sliderElement,
    }

    if options.showAlpha then
        table.insert(interactibleRows, alphaElement)
    end

    local columns = {
        uiElements.column(interactibleRows),
    }

    -- Make sure child elements repaint
    columns[1]:hook({
        update = function(orig, self, dt)
            self:repaint()

            orig(self)
        end
    })

    if #fieldOrder > 0 then
        table.insert(columns, formBody)
    end

    local pickerRow = uiElements.row(columns):with({
        update = fieldUpdater(interactionData)
    })

    return pickerRow
end

return colorPicker