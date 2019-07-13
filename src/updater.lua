local filesystem = require("filesystem")
local github = require("github")
local configs = require("configs")
local utils = require("utils")

-- TODO - Prompt to restart the program afterwards

local updater = {}

-- Only allow if install is "fused" (.exe on Windows) or ran from a .love
function updater.canUpdate()
    return love.filesystem.isFused() or filesystem.fileExtension(love.filesystem.getSource()) == "love"
end

function updater.getAvailableUpdates()
    local success, releases = github.getReleases(configs.updater.github_author, configs.updater.github_repo)
    local res = {}

    for i, release <- releases do
        if release.tag_name then
            table.insert(res, release.tag_name)
        end
    end

    return res
end

function updater.getRelevantRelease(tagName)
    local success, releases = github.getReleases(configs.updater.github_author, configs.updater.github_repo)
    local tagName = tagName or (success and #releases > 0 and releases[1].tag_name)

    if tagName then
        for i, release <- releases do
            if release.tag_name == tagName then
                return true, release
            end
        end
    end

    return false, nil
end

function updater.getRelevantReleaseAsset(tagName, operatingSystem)
    local success, release = updater.getRelevantRelease(tagName)
    local operatingSystem = operatingSystem or love.system.getOS()

    if success then
        for i, asset <- release.assets do
            local assetOS = asset.name:match("-([A-Za-z0-9_]+)%.zip$")

            if assetOS:lower() == operatingSystem:lower() or assetOS:lower():gsub("_", " ") == operatingSystem:lower() then
                return true, asset
            end
        end
    end

    return false, nil
end

-- TODO - Test
-- Make sure this works on at least Windows and Linux, assume that Linux code would work on OS X as well
function updater.update(tagName)
    if updater.canUpdate() then
        local success, asset = updater.getRelevantReleaseAsset(tagName, operatingSystem)

        if success then
            local url = asset.browser_download_url
            local name = asset.name

            local appDir = love.filesystem.getSourceBaseDirectory()
            local userOS = love.system.getOS()

            if userOS == "Windows" then
                -- TODO - Tell user to do stuff themselves
                love.system.openURL(url)

                return true

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