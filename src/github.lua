local utils = require("utils")
local json = require("dkjson")
local hasHttps, https = utils.tryrequire("https")

local github = {}

github._cache = {}
github._cacheTime = 300

github._baseUrl = "https://api.github.com"
github._baseReleasesUrl = github._baseUrl .. "/repos/%s/%s/releases"

local function getUrlJsonData(url, force)
    if not hasHttps then
        return nil
    end

    if github._cache[url] then
        local lastFetch = github._cache[url].time

        if lastFetch + github._cacheTime >= os.time() and not force and github._cache[url].data then
            return github._cache[url].data
        end
    end

    local code, body = https.request(url, {
        headers = {
            ["User-Agent"] = "curl/7.58.0"
        }
    })

    if code == 200 then
        local data = json.decode(body)

        github._cache[url] = {
            time = os.time(),
            data = data
        }

        return data
    end

    return nil
end

function github.getReleases(author, repo)
    local url = string.format(github._baseReleasesUrl, author, repo)

    return getUrlJsonData(url)
end

return github