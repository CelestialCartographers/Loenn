local selene = require("selene")

local libenv = {}
setmetatable(libenv, { __index = _G })
selene.load(libenv)

local lib = {}

lib.libenv = libenv

local _table_blacklist = { "_ENV", "_G" }
do
  local t = {}
  for _, v in pairs(_table_blacklist) do
    t[v] = true
  end
  _table_blacklist = t
end

local function selene_loader(path)
  return function(name)
    local env = setmetatable({}, { __index = _G })
    local source = love.filesystem.read(path)
    local f = assert(libenv.load(libenv._selene._parse(source)))
    setfenv(f, env)
    local result = f()
    if result then
      return result
    end
    local api = {}
    for k, v in pairs(env) do
      if not _table_blacklist[k] then
        api[k] = v
      end
    end
    return api
  end
end

local function selene_searcher(name)
  local _errors = {}

  local fname = name:gsub("%.", "/")

  for pattern in love.filesystem.getRequirePath():gmatch("[^;]+") do

    local fpath = pattern:gsub("%?", fname)
    if love.filesystem.getInfo(fpath, "file") then
      return selene_loader(fpath)
    else
      table.insert(_errors, "\tno file '" .. fpath .. "'")
    end
  end

  return table.concat(_errors, "\n")
end

local function parser()
  return selene.parser
end

function lib.load(index)
  index = index or 2
  local searchers = package.searchers or package.loaders
  if searchers then
    parser() --load the parser
    table.insert(searchers, index, selene_searcher)
  end
end

function lib.unload()
  local searchers = package.searchers or package.loaders
  if searchers then
    for i = 1, #searchers do
      if searchers[i] == selene_searcher then
        table.remove(searchers, i)
        break
      end
    end
  end
end

return lib
