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
    local releases = github.getReleases(configs.updater.github_author, configs.updater.github_repo)
    local res = {}

    for i, release <- releases or {} do
        if release.tag_name then
            table.insert(res, release.tag_name)
        end
    end

    return res
end

function updater.getRelevantRelease(target)
    local releases = github.getReleases(configs.updater.github_author, configs.updater.github_repo)
    local tagName = target or (releases and #releases > 0 and releases[1].tag_name)

    if tagName then
        for i, release <- releases do
            if release.tag_name == tagName then
                return release
            end
        end
    end

    return nil
end

function updater.getRelevantReleaseAsset(tagName, targetOS)
    local release = updater.getRelevantRelease(tagName)
    local userOS = targetOS or love.system.getOS()

    if release then
        for i, asset <- release.assets do
            local assetOS = asset.name:match("-([A-Za-z0-9_]+)%.zip$")

            if assetOS:lower() == userOS:lower() or assetOS:lower():gsub("_", " ") == userOS:lower() then
                return asset
            end
        end
    end

    return nil
end

-- TODO - Test
-- Make sure this works on at least Windows and Linux, assume that Linux code would work on OS X as well
function updater.update(tagName)
    if updater.canUpdate() then
        local asset = updater.getRelevantReleaseAsset(tagName)

        if asset then
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
                local downloaded = filesystem.downloadURL(url, zipPath)

                if downloaded then
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