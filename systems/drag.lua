local drag = system({airResistees = {"drag", "position", "presence"}, translationAirResistees = {"drag", "position", "velocity"}, rotationAirResistees = {"drag", "position", "angularVelocity"}, airs = {"air"}})

local function dampen(entity, velocity, airDensity, dt)
    local speed = #velocity
    if speed > 0 then
        local referenceArea, dragCoefficient
        
        -- TODO
        referenceArea = 2 * detmath.tau * entity.presence.radius ^ 2 / 2
        dragCoefficient = 0.45
        
        local dragForce = 0.5 * speed ^ 2 * referenceArea * dragCoefficient * airDensity
        local newMagnitude = speed - dragForce / entity.mass.val * dt
        velocity = vec3.normalize(velocity) * newMagnitude
    end
    return velocity
end

function drag:update(dt)
	for _, e in ipairs(self.airResistees) do
		local airDensity = 0
		for _, e2 in ipairs(self.airs) do
			airDensity = airDensity + e2.air.val
		end
		
		if self.translationAirResistees:has(e) then
			e.velocity.val = dampen(e, e.velocity.val, airDensity, dt)
		end
		
		if self.rotationAirResistees:has(e) then
			e.angularVelocity.val = dampen(e, e.angularVelocity.val, airDensity, dt)
		end
	end
end

return drag
