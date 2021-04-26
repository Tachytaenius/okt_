local settings = require("settings")

local input = system({pool = {"will", "player"}})

function input:update()
	local world = self:getWorld()
	for _, e in ipairs(self.pool) do
		local x, y, z = 0, 0, 0
		local pitch, yaw, roll = 0, 0, 0
		
		if love.keyboard.isDown(settings.input.left) then x = x - 1 end
		if love.keyboard.isDown(settings.input.right) then x = x + 1 end
		if love.keyboard.isDown(settings.input.down) then y = y - 1 end
		if love.keyboard.isDown(settings.input.up) then y = y + 1 end
		if love.keyboard.isDown(settings.input.forward) then z = z - 1 end
		if love.keyboard.isDown(settings.input.backward) then z = z + 1 end
		
		if love.keyboard.isDown(settings.input.pitchUp) then pitch = pitch + 1 end
		if love.keyboard.isDown(settings.input.pitchDown) then pitch = pitch - 1 end
		if love.keyboard.isDown(settings.input.rollLeft) then roll = roll + 1 end
		if love.keyboard.isDown(settings.input.rollRight) then roll = roll - 1 end
		if love.keyboard.isDown(settings.input.yawLeft) then yaw = yaw + 1 end
		if love.keyboard.isDown(settings.input.yawRight) then yaw = yaw - 1 end
		
		if love.keyboard.isDown(settings.input.brakeTranslation) then
			local relativeVelocity = vec3.rotate(e.velocity.val, quat.inverse(e.orientation.val))
			x = x + math.max(-1, math.min(1, -relativeVelocity.x / (relativeVelocity.x < 0 and e.thrusters.right or e.thrusters.left) * e.mass.val / consts.tickLength))
			y = y + math.max(-1, math.min(1, -relativeVelocity.y / (relativeVelocity.y < 0 and e.thrusters.up or e.thrusters.down) * e.mass.val / consts.tickLength))
			z = z + math.max(-1, math.min(1, -relativeVelocity.z / (relativeVelocity.z < 0 and e.thrusters.backward or e.thrusters.forward) * e.mass.val / consts.tickLength))
		end
		
		if love.keyboard.isDown(settings.input.brakeRotation) then
			pitch = pitch + math.max(-1, math.min(1, -e.angularVelocity.val.x / (e.angularVelocity.val.x < 0 and e.thrusters.pitchUp or e.thrusters.pitchDown)  * e.mass.val / consts.tickLength))
			yaw = yaw + math.max(-1, math.min(1, -e.angularVelocity.val.y / (e.angularVelocity.val.y < 0 and e.thrusters.yawLeft or e.thrusters.yawRight)  * e.mass.val / consts.tickLength))
			roll = roll + math.max(-1, math.min(1, -e.angularVelocity.val.z / (e.angularVelocity.val.z < 0 and e.thrusters.rollLeft or e.thrusters.rollRight)  * e.mass.val / consts.tickLength))
		end
		
		e.will.translationMultiplier, e.will.rotationMultiplier = vec3(x, y, z), vec3(pitch, yaw, roll)
		
		e.will.shoot = love.keyboard.isDown(settings.input.shoot)
	end
end

return input
