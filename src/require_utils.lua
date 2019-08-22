local utils = {}

local shownWarningFor = {}

function utils.tryrequire(lib, verbose)
    verbose = verbose == nil or verbose

    local success, res = pcall(require, lib)

    if not success then
        if not shownWarningFor[lib] and verbose then
            print("! Failed to require '" .. lib .. "'")
            print(res)

            shownWarningFor[lib] = true
        end
    end

    return success, res
end

-- Clear the cache of a required library
function utils.unrequire(lib)
    package.loaded[lib] = nil
end

-- Clear the cache and return a new uncached version of the library
-- Highly unrecommended to use this for anything
function utils.rerequire(lib)
    utils.unrequire(lib)

    return require(lib)
end

return utils