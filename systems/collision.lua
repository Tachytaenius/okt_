local physics = system({colliders = {"presence", "mass", "position", "velocity"}})

local sphereSphereCollision

function physics:update(dt)
	local collisions = {}
	for i = 1, #self.colliders - 1 do
		local collider1 = self.colliders[i]
		
		for j = i + 1, #self.colliders do
			local collider2 = self.colliders[j]
			
			local temp = sphereSphereCollision
			collisions[#collisions + 1] = temp(collider1, collider2)
		end
	end
	
	for _, collider in ipairs(self.colliders) do
		collider.velocity.nextVal = collider.velocity.val
	end
	
	-- For order independence we will use velocity.val when getting and velocity.nextVal when setting
	for _, collision in ipairs(collisions) do
		local collider1, collider2 = collision.collider1, collision.collider2
		
		local direction = vec3.normalize(collider2.position.val - collider1.position.val)
		local velocityDifference = collider2.velocity.val - collider1.velocity.val
		local impactSpeed = vec3.dot(velocityDifference, direction)
		if impactSpeed < 0 then
			local m1, m2 = collider1.mass.val, collider2.mass.val
			--[[ Cases:
			0 vs 0                set to 1 vs 1
			0 vs "normal"         works
			0 vs infinity         set to 0 vs 1
			"normal" vs 0         works
			"normal" vs "normal"  works
			"normal" vs infinity  set to 0 vs 1
			infinity vs 0         set to 1 vs 0
			infinity vs "normal"  set to 1 vs 0
			infinity vs infinity  set to 1 vs 1
			]]
			if m1 == m2 then
				m1, m2 = 1, 1
			elseif m1 == math.huge then
				if m2 == math.huge then
					m1, m2 = 1, 1
				else
					m1, m2 = 1, 0
				end
			elseif m2 == math.huge then
				m1, m2 = 0, 1
			end
			local speed1 = (2 * m2 * impactSpeed) / (m1 + m2)
			local speed2 = (impactSpeed * (m2 - m1)) / (m1 + m2)
			collider1.velocity.nextVal = collider1.velocity.val + direction * speed1
			collider2.velocity.nextVal = collider2.velocity.val + direction * (speed2 - impactSpeed)
		end
	end
	
	for _, collider in ipairs(self.colliders) do
		collider.velocity.val, collider.velocity.nextVal = collider.velocity.nextVal
	end
end

function sphereSphereCollision(collider1, collider2)
	local radiusDistance = collider1.presence.radius + collider2.presence.radius
	local centreDistance = vec3.distance(collider1.position.val, collider2.position.val)
	
	if centreDistance < radiusDistance then
		return {
			collider1 = collider1, collider2 = collider2
		}
	end
end

return physics