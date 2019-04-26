local filesystem = require("filesystem")
local github = require("github")
local configs = require("configs")

-- TODO - Prompt to restart the program afterwards
-- TODO - Track "current" version

local updater = {}

-- Only allow if install is "fused" (.exe on Windows) or ran from a .love
function updater.canUpdate()
    return love.filesystem.isFused() or filesystem.fileExtension(love.filesystem.getSource()) == "love"
end

function updater.getRelevantRelease(releaseId)
    local success, releases = github.getReleases(configs.updater.github_author, configs.updater.github_repo)
    local releaseId = releaseId or (success and #releases > 0 and releases[1].id)

    if releaseId then
        for i, release <- releases do
            if release.id == releaseId then
                return true, release
            end
        end
    end

    return false, nil
end

function updater.getRelevantReleaseAsset(releaseId, operatingSystem)
    local success, release = updater.getRelevantRelease(releaseId)
    local operatingSystem = operatingSystem or love.system.getOS()

    if success then
        for i, asset <- release.assets do
            if asset.name:match("-" .. operatingSystem .. ".zip$") then
                return true, asset
            end
        end
    end

    return false, nil
end

-- TODO - Test
-- Make sure this works on at least Windows and Linux, assume that Linux code would work on OS X as well
function updater.update(releaseId)
    if updater.canUpdate() then
        local success, asset = updater.getRelevantReleaseAsset(releaseId, operatingSystem)

        if success then
            local url = asset.browser_download_url
            local name = asset.name

            local appDir = love.filesystem.getSourceBaseDirectory()
            local userOS = love.system.getOS() 

            if userOS == "Windows" then
                -- TODO

                return false

            elseif userOS == "Linux" then
                -- TODO - Sanitize this
                -- Move current files into .old or equivalent
                -- Download and extract files, and then delete .old

                local zipPath = filesystem.joinpath(appDir, name)
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
    end

    return false
end

return updater