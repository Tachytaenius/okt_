local shooting = system({pool = {"will", "position", "orientation", "guns"}})

function shooting:update(dt)
	for _, e in ipairs(self.pool) do
		if e.will.shoot then -- if not e.will.shoot then continue end >:(
			if e.guns.cooldown == 0 then
				local theta, phi =
					(love.math.random() - 0.5) * e.guns.spreadAngle,
					(love.math.random() - 0.5) * e.guns.spreadAngle
				local direction = vec3.rotate(vec3.detFromAngles(theta - math.tau / 4, phi), e.orientation.val) -- TODO: Revise understanding of how quats, vecs and such relate in the various spaces they exist in in this engine. (AKA "why do we have to subtract quarter tau")
				
				if type(e.will.shoot) ~= "boolean" then
					direction = 
				end
				
				local velocity = direction * e.guns.speed
				if e.velocity then
					velocity = velocity + e.velocity.val
				end
				local position = e.position.val - vec3.rotate(e.guns.muzzlePos, -e.orientation.val)
				
				local projectile = entity():assemble(assemblages[e.guns.projectile])
				projectile.velocity.val, projectile.position.val = velocity, position
				if projectile.orientation then
					projectile.orientation.val = e.orientation.val
				end
				
				local entitiesToAdd = self:getWorld().entitiesToAdd
				entitiesToAdd[#entitiesToAdd + 1] = projectile
				e.guns.cooldown = e.guns.fireRate
			end
		end
		e.guns.cooldown = math.max(e.guns.cooldown - dt, 0)
	end
end

return shooting
