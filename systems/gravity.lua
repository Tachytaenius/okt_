local gravity = system({gravitatees = {"gravitationalAcceleration", "position", "velocity"}, gravities = {"gravity"}})

function gravity:update(dt)
	for _, e in ipairs(self.gravitatees) do
		local gravity = vec3()
		for _, e2 in ipairs(self.gravities) do
			gravity = gravity + e2.gravity.val
		end
		e.velocity.val = e.velocity.val + gravity * dt
	end
end

return gravity
