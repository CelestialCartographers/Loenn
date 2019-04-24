local filesystem = require("filesystem")

-- TODO - Add way to get the correct url for updating
-- TODO - Prompt to restart the program afterwards

local updater = {}

-- Only allow if install is "fused" (.exe on Windows) or ran from a .love
function updater.canUpdate()
    return love.filesystem.isFused() or filesystem.fileExtension(love.filesystem.getSource()) == "love"
end

-- TODO - Test
-- Make sure this works on at least Windows and Linux, assume that Linux code would work on OS X as well
function updater.update(url)
    if updater.canUpdate() then
        local appDir = love.filesystem.getSourceBaseDirectory()
        local userOS = love.system.getOS() 

        if userOS == "Windows" then
            -- TODO

            return false

        elseif userOS == "Linux" then
            -- TODO - Sanitize this
            -- Move current files into .old or equivalent
            -- Download and extract files, and then delete .old

            local zipPath = filesystem.joinpath(appDir, "update.zip")
            local success = filesystem.downloadURL(url, zipPath)

            if success then
                filesystem.unzip(zipPath, appDir)

                filesystem.remove(zipPath)

                return true
            end

        elseif userOS == "OS X" then
            -- TODO

            return false
        end
    end

    return false
end

return updater