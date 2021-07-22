local utils = require("utils")
local json = require("dkjson")
local hasRequest, request = utils.tryrequire("luajit-request.luajit-request")

local github = {}

github._cache = {}
github._cacheTime = 300

github._baseUrl = "https://api.github.com"
github._baseReleasesUrl = github._baseUrl .. "/repos/%s/%s/releases"

local headers = {
    ["User-Agent"] = "curl/7.78.0",
    ["Accept"] = "*/*"
}

local function getUrlJsonData(url, force)
    if not hasRequest then
        return nil
    end

    if github._cache[url] then
        local lastFetch = github._cache[url].time

        if lastFetch + github._cacheTime >= os.time() and not force and github._cache[url].data then
            return github._cache[url].data
        end
    end

    local response = request.send(url, {headers = headers})

    if response then
        local code, body = response.code, response.body

        if code == 200 then
            local data = json.decode(body)

            if type(data) == "table" then
                github._cache[url] = {
                    time = os.time(),
                    data = data
                }

                return data
            end
        end
    end
end

function github.getReleases(author, repo)
    local url = string.format(github._baseReleasesUrl, author, repo)

    return getUrlJsonData(url)
end

return github