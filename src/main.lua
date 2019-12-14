function love.load()
    local path = "selene/selene/lib/?.lua;selene/selene/lib/?/init.lua;" .. love.filesystem.getRequirePath()
    love.filesystem.setRequirePath(path)

    -- The English language contains over 500,000 words and not a single one of them is suitable for describing just how much I want to purge macos from existence.
    if love.system.getOS() == "OS X" then
        package.cpath = package.cpath .. ";" .. love.filesystem.getSourceBaseDirectory() .. "/?.so"
    end

    require("selene").load()
    require("selene/selene/wrappers/searcher/love2d/searcher").load()

    require("selene_main")
end