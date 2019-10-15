local keyboard = {}

function keyboard.modifierControl()
    return love.keyboard.isDown("lctrl") or love.keyboard.isDown("rctrl")
end

function keyboard.modifierShift()
    return love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
end

function keyboard.modifierAlt()
    return love.keyboard.isDown("lalt") or love.keyboard.isDown("ralt")
end

-- Command on Mac, Windows key on Windows
function keyboard.modifierGUI()
    return love.keyboard.isDown("lgui") or love.keyboard.isDown("rgui")
end

keyboard.nameToModifierFunction = {
    ctrl = keyboard.modifierControl,
    shift = keyboard.modifierShift,
    alt = keyboard.modifierAlt,
    gui = keyboard.modifierGUI,
}

return keyboard