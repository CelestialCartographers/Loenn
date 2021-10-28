local colors = {}

-- Missing tileset colors
colors.tileFGMissingColor = {120 / 255, 81 / 255, 169 / 255}
colors.tileBGMissingColor = {255 / 255, 195 / 255, 11 / 255}

colors.entityMissingColor = {47 / 255, 114 / 255, 100 / 255, 0.75}
colors.entityErrorColor = {255 / 255, 0 / 255, 0 / 255, 0.75}
colors.triggerColor = {47 / 255, 114 / 255, 100 / 255, 0.3}
colors.triggerBorderColor = {38 / 255, 91 / 255, 80 / 255, 0.7}
colors.triggerTextColor = {255 / 255, 255 / 255, 255 / 255}

-- Room background colors
colors.roomBorderColors = {
    {255 / 255, 255 / 255, 255 / 255},
    {246 / 255, 115 / 255, 94 / 255},
    {133 / 255, 246 / 255, 94 / 255},
    {55 / 255, 215 / 255, 227 / 255},
    {55 / 255, 107 / 255, 227 / 255},
    {195 / 255, 55 / 255, 227 / 255},
    {227 / 255, 55 / 255, 115 / 255}
}

colors.roomBackgroundColors = {
    {50 / 255, 50 / 255, 50 / 255},
    {62 / 255, 51 / 255, 51 / 255},
    {51 / 255, 62 / 255, 51 / 255},
    {51 / 255, 54 / 255, 57 / 255},
    {51 / 255, 51 / 255, 64 / 255},
    {60 / 255, 51 / 255, 63 / 255},
    {57 / 255, 51 / 255, 51 / 255}
}

colors.roomBackgroundDefault = {50 / 255, 50 / 255, 50 / 255}
colors.roomBorderDefault = {255 / 255, 255 / 255, 255 / 255}

-- Color of filler objects
colors.fillerColor = {68 / 255, 68 / 255, 68 / 255}
colors.fillerSelectedColor = {78 / 255, 108 / 255, 78 / 255}

-- Brush tool color
colors.brushColor = {77 / 255, 77 / 255, 77 / 255, 204 / 255}

-- Selection tool selection rectangle
colors.selectionBorderColor = {0 / 255, 255 / 255, 77 / 255, 153 / 255}
colors.selectionFillColor = {0 / 255, 255 / 255, 77 / 255, 102 / 255}

-- Selection tool selection item preview
colors.selectionPreviewBorderColor = {255 / 255, 255 / 255, 0 / 255, 153 / 255}
colors.selectionPreviewFillColor = {255 / 255, 255 / 255, 0 / 255, 102 / 255}
colors.selectionPreviewNodeLineColor = {255 / 255, 255 / 255, 0 / 255, 102 / 255}

-- Selection tool selected item
colors.selectionCompleteBorderColor = {255 / 255, 0 / 255, 255 / 255, 153 / 255}
colors.selectionCompleteFillColor = {255 / 255, 0 / 255, 255 / 255, 102 / 255}
colors.selectionCompleteNodeLineColor = {255 / 255, 0 / 255, 255 / 255, 102 / 255}

-- Selection tool axis bound movement
colors.selectionAxisBoundMovementLines = {255 / 255, 255 / 255, 0 / 255, 153 / 255}
colors.selectionAxisBoundSelectionBackground = {255 / 255, 0 / 255, 255 / 255, 102 / 255}

-- Resize arrows device
colors.resizeTriangleColor = {196 / 255, 196 / 255, 196 / 255}

-- Default color
colors.default = {255 / 255, 255 / 255, 255 / 255}

return colors