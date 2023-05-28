local fzy = require("lib.fzy_lua")
local utils = require("utils")

local textSearching = {}

function textSearching.contains(text, search, caseSensitive, fuzzy)
    if not caseSensitive and not fuzzy then
        text = text:lower()
        search = search:lower()
    end

    if fuzzy then
        return fzy.has_match(search, text, caseSensitive)

    else
        return string.contains(text, search)
    end
end

function textSearching.filter(items, search, caseSensitive, fuzzy)
    return utils.filter(function(item)
        return textSearching.contains(item, search, caseSensitive, fuzzy)
    end)
end

local largeNumber = 2^30

-- Higher is better, nil if no match
-- Naive scoring method for non fuzzy, can be improved later
function textSearching.searchScore(text, search, caseSensitive, fuzzy)
    -- Edge case for fuzzy search
    if not search or search == "" then
        return math.huge
    end

    if not caseSensitive and not fuzzy then
        text = text:lower()
        search = search:lower()
    end

    if fuzzy then
        if fzy.has_match(search, text, caseSensitive) then
            local postitions, score = fzy.positions(search, text, caseSensitive)

            return score
        end

    else
        local start = string.find(text, search, nil, true)

        if start then
            return largeNumber - start
        end
    end
end

return textSearching