local drawableFunction = {}

function drawableFunction.fromFunction(func, ...)
    local drawable = {
        _type = "drawableFunction"
    }

    drawable.func = func
    drawable.args = {...}

    return drawable
end

return drawableFunction