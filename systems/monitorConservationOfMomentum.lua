local movement = system({entitiesWithMomenta = {"mass", "velocity"}})

function movement:update(dt)
	local totalMomentum = vec3()
	for _, entity in ipairs(self.entitiesWithMomenta) do
		local entityMomentum = entity.mass.val * entity.velocity.val
		totalMomentum = totalMomentum + entityMomentum
	end
	print(totalMomentum)
end

return movement
