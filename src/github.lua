local json = require("dkjson")
local https = require("https")

local github = {}

github._baseUrl = "https://api.github.com"
github._baseReleasesUrl = github._baseUrl .. "/repos/%s/%s/releases"

local function getUrlJsonData(url)
    local resp = {}

    local code, body = https.request(url, {
        headers = {
            ["User-Agent"] = "curl/7.58.0"
        }
    })

    if code == 200 then
        return true, json.decode(body)
    end

    return false, nil
end

function github.getReleases(author, repo)
    local url = string.format(github._baseReleasesUrl, author, repo)

    return getUrlJsonData(url)
end

return github