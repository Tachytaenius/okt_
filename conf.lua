local settings = require("settings")

function love.conf(t)
	t.window.width = settings.graphics.width
	t.window.height = settings.graphics.height
end
