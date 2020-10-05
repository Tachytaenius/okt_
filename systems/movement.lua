local movement = system({translatees = {"position", "velocity"}, rotatees = {"orientation", "angularVelocity"}})

function movement:update(dt)
	for _, e in ipairs(self.translatees) do
		e.position.val = e.position.val + e.velocity.val * dt
	end
	
	for _, e in ipairs(self.rotatees) do
		e.orientation.val = quat.normalize(e.orientation.val * quat.fromAxisAngle(e.angularVelocity.val * dt)) -- Normalise to prevent numerical drift
	end
end

return movement
