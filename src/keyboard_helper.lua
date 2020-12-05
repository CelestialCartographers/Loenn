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
    control = keyboard.modifierControl,

    shift = keyboard.modifierShift,

    alt = keyboard.modifierAlt,

    gui = keyboard.modifierGUI,
    commmand = keyboard.modifierGUI,
    cmd = keyboard.modifierGUI,
    windows = keyboard.modifierGUI,
    winkey = keyboard.modifierGUI
}

function keyboard.modifierHeld(modifier)
    local modifierFunction = keyboard.nameToModifierFunction[modifier]

    if modifierFunction then
        return modifierFunction()
    end

    return false
end

return keyboard