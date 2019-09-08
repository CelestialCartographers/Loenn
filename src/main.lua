function love.load()
    local path = "selene/selene/lib/?.lua;selene/selene/lib/?/init.lua;" .. love.filesystem.getRequirePath()

    love.filesystem.setRequirePath(path)

    love.filesystem.mount(love.filesystem.getSourceBaseDirectory(), "", true)

    require("selene").load()
    require("selene/selene/wrappers/searcher/love2d/searcher").load()

    require("selene_main")
end