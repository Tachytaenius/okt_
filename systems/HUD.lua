local settings = require("settings")

local HUD = system({cameras = {"camera", "position", "orientation"}, gravities = {"gravity"}})

function HUD:init()
	self.width, self.height = settings.graphics.width, settings.graphics.height
	self.output = love.graphics.newCanvas(self.width, self.height)
end

function HUD:draw(lerp)
	local camera = self.cameras[1]
	if not camera then return end
	
	love.graphics.push("all")
	love.graphics.setCanvas(self.output)
	love.graphics.clear(0, 0, 0, 0)
	
	local gravitation = vec3()
	for _, e in ipairs(self.gravities) do
		gravitation = gravitation + e.gravity.ival
	end
	
	local relativeGravitation = vec3.rotate(gravitation, quat.inverse(camera.orientation.ival))
	local direction = vec3.normalize(relativeGravitation)
	
	local radius = 30
	love.graphics.translate(radius + 5, radius + 5)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle("fill", 0, 0, radius)
	love.graphics.setColor(0, 0, 0)
	love.graphics.circle("line", 0, 0, radius)
	love.graphics.circle(direction.z > 0 and "line" or "fill", direction.x * radius, direction.y * radius, 3)
	
	love.graphics.pop()
end

return HUD
