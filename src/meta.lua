local utils = require("utils")
local version = require("utils.version_parser")

local meta = {}

meta.title = utils.readAll("assets/TITLE", "rb", true)
meta.version = version(utils.readAll("assets/VERSION", "rb", true))

return meta