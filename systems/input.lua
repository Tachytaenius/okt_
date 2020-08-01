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
			local relativeVelocity = vec3.rotate(e.velocity.val, e.orientation.val)
			x = x + math.max(-1, math.min(1, -relativeVelocity.x / (relativeVelocity.x < 0 and e.thrusters.right or e.thrusters.left)))
			y = y + math.max(-1, math.min(1, -relativeVelocity.y / (relativeVelocity.y < 0 and e.thrusters.up or e.thrusters.down)))
			z = z + math.max(-1, math.min(1, -relativeVelocity.z / (relativeVelocity.z < 0 and e.thrusters.backward or e.thrusters.forward)))
		end
		
		if love.keyboard.isDown(settings.input.brakeRotation) then
			pitch = pitch + math.max(-1, math.min(1, -e.angularVelocity.val.x))
			yaw = yaw + math.max(-1, math.min(1, -e.angularVelocity.val.y))
			roll = roll + math.max(-1, math.min(1, -e.angularVelocity.val.z))
		end
		
		e.will.translationMultiplier, e.will.rotationMultiplier = vec3(x, y, z), vec3(pitch, yaw, roll)
		
		-- TEMP
		if love.keyboard.isDown("space") then
			local bullet = entity():
				give("velocity", vec3.components(e.velocity.val + vec3.rotate(vec3(0, 0, -1), e.orientation.val) * 100)):
				give("position", vec3.components(e.position.val)):
				give("drawable", "boi"):
				give("orientation", quat.components(e.orientation.val))
			world.entitiesToAdd[#world.entitiesToAdd + 1] = bullet
		end
	end
end

return input
