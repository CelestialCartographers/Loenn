require("lua_setup")

local meta = require("meta")
local configs = require("configs")
local persistence = require("persistence")

function love.conf(t)
	t.console = true

	t.title = meta.title
	t.window.resizable = true
	t.window.minwidth = 1280
	t.window.width = 1280
	t.window.minheight = 720
	t.window.height = 720

	t.window.icon = "assets/logo-256.png"

	t.window.vsync = true
end