return {
    -- Tools and Interactions
    toolActionButton = 1,
    contextMenuButton = 2,
    canvasMoveButton = 2,
    canvasZoomExtentsButton = 3,
    objectCloneButton = 3,

    copyUsesClipboard = true,
    pasteCentered = true,

    -- Modifier Keys
    selectionAddModifier = "shift",
    movementAxisBoundModifier = "shift",
    precisionModifier = "ctrl",

    -- Item Movement
    itemAllowPixelPerfect = false,
    itemMoveLeft = "left",
    itemMoveRight = "right",
    itemMoveUp = "up",
    itemMoveDown = "down",

    itemResizeLeftGrow = false,
    itemResizeRightGrow = "e",
    itemResizeUpGrow = false,
    itemResizeDownGrow = "d",
    itemResizeLeftShrink = false,
    itemResizeRightShrink = "q",
    itemResizeUpShrink = false,
    itemResizeDownShrink = "a",

    itemRotateLeft = "l",
    itemRotateRight = "r",

    itemFlipVertical = "v",
    itemFlipHorizontal = "h",

    itemDelete = "delete",

    itemAddNode = "n",

    -- Rendering
    prepareRoomRenderInBackground = true,
    alwaysRedrawUnselectedRooms = false,

    -- Loading
    lazyLoadExternalAtlases = true,

    -- History
    historyEntryLimit = false,

    -- Recent Files
    recentFilesEntryLimit = 8,

    -- Debug
    displayFPS = false,
    warnOnMissingTexture = false,
    warnOnMissingEntityHandler = false,

    -- Persistence
    toolsPersistUsingGroup = true,

    -- Save sanitizers
    sortRoomsOnSave = true,
    checkDependenciesOnSave = true,
}