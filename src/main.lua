function love.load()
    local path = "selene/selene/lib/?.lua;selene/selene/lib/?/init.lua;" .. love.filesystem.getRequirePath()
    love.filesystem.setRequirePath(path)

    -- The English language contains over 500,000 words and not a single one of them is suitable for describing just how much I want to purge macos from existence.
    if love.system.getOS() == "OS X" then
        package.cpath = package.cpath .. ";" .. love.filesystem.getSourceBaseDirectory() .. "/?.so"
    end

    -- Keeping it here since it is an option, and seems to make a difference at some points
    -- Attempt to expose to config option at some point
    --[[
    _G._selene = {}
    _G._selene.notypecheck = true
    ]]

    require("selene").load()
    require("selene/selene/wrappers/searcher/love2d/searcher").load()

    require("selene_main")
end