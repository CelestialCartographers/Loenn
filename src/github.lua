-- TODO - Figure out how to ship luasec on Linux/Windows
-- Worst case make this optional

local json = require("dkjson")
local https = require("ssl.https")
local sslurl = require("socket.url")
local ltn12  = require("ltn12")
local utils = require("utils")

--https.cfg.options = {"all", "no_sslv2", "no_sslv3", "no_tlsv1"}

local github = {}

github._baseUrl = "https://api.github.com"
github._baseReleasesUrl = github._baseUrl .. "/repos/%s/%s/releases"

local function getUrlJsonData(url)
    local resp = {}

    -- Probably wrong names, but code is correct at least
    local body, code, headers, status = https.request({
        url = url,
        sink = ltn12.sink.table(resp),
        protocol = "tlsv1_2"
    })

    if code == 200 then
        return true, json.decode(table.concat(resp, ""))
    end

    return false, nil
end

function github.getReleases(author, repo)
    local url = string.format(github._baseReleasesUrl, author, repo)

    return getUrlJsonData(url)
end

return github