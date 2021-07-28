local filesystem = require("filesystem")
local github = require("github")
local configs = require("configs")
local persistence = require("persistence")
local utils = require("utils")
local meta = require("meta")
local versionParser = require("version_parser")
local sceneHandler = require("scene_handler")
local threadHandler = require("thread_handler")

-- TODO - Prompt to restart the program afterwards

local updater = {}

-- Only allow if install is "fused" (.exe on Windows) or ran from a .love
function updater.canUpdate()
    return love.filesystem.isFused() or filesystem.fileExtension(love.filesystem.getSource()) == "love"
end

function updater.getAvailableVersions(sort)
    local releases = github.getReleases(configs.updater.githubAuthor, configs.updater.githubRepository)
    local res = {}

    for i, release in ipairs(releases or {}) do
        if release.tag_name then
            table.insert(res, versionParser(release.tag_name))
        end
    end

    -- Newest first
    if sort ~= false then
        table.sort(res, function(lhs, rhs) return lhs > rhs end)
    end

    return res
end

-- Check if we are up to date or not
-- Assume we are up to date if we don't have any available versions
function updater.isLatestVersion()
    local current = meta.version
    local availableVersions = updater.getAvailableVersions()

    if availableVersions and #availableVersions > 0 then
        local latest = availableVersions[1]

        return latest == current, latest
    end

    return true
end

function updater.getRelevantRelease(tagName)
    local releases = github.getReleases(configs.updater.githubAuthor, configs.updater.githubRepository)

    if tagName then
        local targetVersion = versionParser(tagName)

        for _, release in ipairs(releases or {}) do
            local releaseVersion = versionParser(release.tag_name)

            if targetVersion == releaseVersion then
                return release
            end
        end

    else
        return releases[1]
    end
end

function updater.getRelevantReleaseAsset(tagName, targetOS)
    local release = updater.getRelevantRelease(tagName)
    local userOS = targetOS or love.system.getOS()
    local userOSLower = userOS:lower()

    if release then
        for _, asset in ipairs(release.assets) do
            local assetOS = asset.name:match("-([A-Za-z0-9_]+)%.zip$")

            if assetOS then
                local assetOSLower = assetOS:lower()

                if assetOSLower == userOSLower or assetOSLower:gsub("_", " ") == userOSLower then
                    return asset
                end
            end
        end
    end
end

function updater.openDownloadPage(tagNameOrAsset)
    local asset = tagNameOrAsset

    if type(tagNameOrAsset) == "string" then
        asset = updater.getRelevantReleaseAsset(tagNameOrAsset)
    end

    if asset then
        local url = asset.browser_download_url
        local name = asset.name

        love.system.openURL(url)

        return true
    end

    return false
end

-- For now this should just start the download in the browser
-- Make it more sane for the user later on
-- Keep the if statements for now, they are pointless for this use case but sane for the future
function updater.update(tagName)
    if updater.canUpdate() then
        local asset = updater.getRelevantReleaseAsset(tagName)

        if asset then
            local url = asset.browser_download_url
            local name = asset.name

            local appDir = love.filesystem.getSourceBaseDirectory()
            local userOS = love.system.getOS()

            if userOS == "Windows" then
                return updater.openDownloadPage(asset)

            elseif userOS == "Linux" then
                return updater.openDownloadPage(asset)

            elseif userOS == "OS X" then
                return updater.openDownloadPage(asset)
            end
        end
    end

    return false
end

-- Check for updates and queue up related events
function updater.checkForUpdates()
    local code = [[
        require("selene").load()
        require("selene/selene/wrappers/searcher/love2d/searcher").load()
        require("love.system")

        local args = {...}
        local channelName = unpack(args)
        local channel = love.thread.getChannel(channelName)

        local updater = require("updater")
        local meta = require("meta")

        if updater.canUpdate() then
            channel:push({"updaterCheckingForUpdates"})

            local isLatest, latestVersion = updater.isLatestVersion()

            if not isLatest then
                -- Metatables are lost over channels
                channel:push({"updaterUpdateAvailable", tostring(latestVersion), tostring(meta.version)})
            end
        end
    ]]

    return threadHandler.createStartWithCallback(code, function(event)
        sceneHandler.sendEvent(unpack(event))
    end)
end

function updater.startupUpdateCheck()
    if configs.updater.checkOnStartup then
        updater.checkForUpdates()
    end
end

return updater