local thrust = system({pool = {"will", "thrusters", "orientation", "velocity", "angularVelocity"}})

function thrust:update(dt)
	for _, e in ipairs(self.pool) do
		if e.will.translationMultiplier then
			local maximumTranslateForce = vec3(
				e.will.translationMultiplier.x > 0 and e.thrusters.right or e.thrusters.left,
				e.will.translationMultiplier.y > 0 and e.thrusters.up or e.thrusters.down,
				e.will.translationMultiplier.z > 0 and e.thrusters.backward or e.thrusters.forward
			)
			local translateForce = e.will.translationMultiplier * maximumTranslateForce
			e.velocity.val = e.velocity.val + vec3.rotate(translateForce / e.mass.val * dt, e.orientation.val)
		end
		
		if e.will.rotationMultiplier then
			local maximumAngularForce = vec3(
				e.will.rotationMultiplier.x > 0 and e.thrusters.pitchUp or e.thrusters.pitchDown,
				e.will.rotationMultiplier.y > 0 and e.thrusters.yawLeft or e.thrusters.yawRight,
				e.will.rotationMultiplier.z > 0 and e.thrusters.rollLeft or e.thrusters.rollRight
			)
			local angularForce = e.will.rotationMultiplier * maximumAngularForce
			e.angularVelocity.val = e.angularVelocity.val + angularForce / e.mass.val * dt
		end
	end
end

return thrust
