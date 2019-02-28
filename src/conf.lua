function love.conf(t)
	t.console = true

	t.window.resizable = true
	t.window.minwidth = 640
	t.window.minheight = 480

	-- Keeping VSync off to check performance, as smoothness is key here
	t.window.vsync = false
end