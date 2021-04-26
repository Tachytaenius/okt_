local json = require("lib.json")

local settings = {}

settings.graphics = {
	width = 480,
	height = 270
}

settings.input = {
	forward = "w",
	backward = "s",
	left = "a",
	right = "d",
	up = "e",
	down = "q",
	
	pitchUp = "i",
	pitchDown = "k",
	yawLeft = "j",
	yawRight = "l",
	rollLeft = "u",
	rollRight = "o",
	
	brakeTranslation = "lshift",
	brakeRotation = "lctrl",
	
	shoot = "space"
}

return settings
