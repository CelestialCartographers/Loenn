local utils = require("utils")
local matrixLib = require("utils.matrix")

local resizeCursorMatrix = matrixLib.fromTable(
    {
        "sizenwse", "sizens", "sizenesw",
        "sizewe", "sizeall", "sizewe",
        "sizenesw", "sizens", "sizenwse"
    }, 3, 3
)

local cursorUtils = {}

cursorUtils.previousCursor = "arrow"

function cursorUtils.getDefaultCursor()
    return "arrow"
end

function cursorUtils.getWaitCursor()
    return "waitarrow"
end

function cursorUtils.getStopCursor()
    return "no"
end

function cursorUtils.getMoveCursor()
    return "hand"
end

function cursorUtils.getResizeCursor(directionX, directionY)
    local signX = utils.sign(directionX)
    local signY = utils.sign(directionY)

    return resizeCursorMatrix:get(signX + 2, signY + 2, cursorUtils.getDefaultCursor())
end

function cursorUtils.useDefaultCursor()
    cursorUtils.setCursor(cursorUtils.getDefaultCursor())
end

function cursorUtils.useWaitCursor()
    cursorUtils.setCursor(cursorUtils.getWaitCursor())
end

function cursorUtils.useStopCursor()
    cursorUtils.setCursor(cursorUtils.getStopCursor())
end

function cursorUtils.useMoveCursor()
    cursorUtils.setCursor(cursorUtils.getMoveCursor())
end

function cursorUtils.useResizeCursor(directionX, directionY)
    cursorUtils.setCursor(cursorUtils.getResizeCursor(directionX, directionY))
end

-- previousCursor can be used to prevent updating cursor when the user thinks it is correct
-- Prevents fighting between two users of setCursor
function cursorUtils.setCursor(cursor, previousCursor, force)
    if cursor ~= previousCursor then
        if force or cursor ~= cursorUtils.previousCursor then
            love.mouse.setCursor(love.mouse.getSystemCursor(cursor))

            cursorUtils.previousCursor = cursor
        end

        return cursor

    else
        return previousCursor
    end
end

return cursorUtils