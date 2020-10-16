local physics = system({colliders = {"presence", "mass", "position", "velocity"}})

local sphereSphereCollision, sphereTriangleCollision

function physics:init()
	self.levelTriangles = {}
	self:addTriangle(vec3(-10,-10,-3),vec3(10,10,-3),vec3(-10,10,-3),0.2)
	self:addTriangle(vec3(-10,-10,-3),vec3(10,-10,-3),vec3(10,10,-3),0.2)
end

function physics:addTriangle(p1, p2, p3, restitution)
	-- Normal and distance define the plane the triangle lies on
	local normal = vec3.normalize(vec3.cross(p2 - p1, p3 - p1))
	local distance = vec3.dot(p1, normal)
	self.levelTriangles[#self.levelTriangles + 1] = {p1 = p1, p2 = p2, p3 = p3, normal = normal, distance = distance, restitution = restitution}
end

function physics:update(dt)
	local collisions, staticCollisions, numCollisions = {}, {}, {}
	for i = 1, #self.colliders - 1 do
		local collider1 = self.colliders[i]
		local type1 = collider1.presence.type
		
		for j = 1, #self.levelTriangles do
			local triangle = self.levelTriangles[j]
			
			local success, direction, distance
			if type1 == "sphere" then
				success, direction, distance = sphereTriangleCollision(collider1.position.val, collider1.presence.radius, triangle.p1, triangle.p2, triangle.p3, triangle.normal, triangle.distance)
			end
			
			if success then
				local restitution1 = collider1.restitution and collider1.restitution.val or 1
				local restitution2 = triangle.restitution or 1
				local restitution = math.min(restitution1, restitution2)
				
				staticCollisions[#staticCollisions + 1] = {collider = collider1, direction = direction, distance = distance, restitution = restitution}
				numCollisions[collider1] = numCollisions[collider1] and numCollisions[collider1] + 1 or 1
			end
		end
		
		for j = i + 1, #self.colliders do
			local collider2 = self.colliders[j]
			numCollisions[collider2] = 0
			local type2 = collider2.presence.type
			
			local success, direction, distance
			if type1 == "sphere" then
				if type2 == "sphere" then
					success, direction, distance = sphereSphereCollision(collider1.position.val, collider1.presence.radius, collider2.position.val, collider2.presence.radius)
				elseif type2 == "aabb" then
					collisionFunction = sphereAabbCollision
				end
			elseif type1 == "aabb" then
				if type2 == "sphere" then
					collider1, collider2 = collider2, collider1
					collisionFunction = sphereAabbCollision
				elseif type2 == "aabb" then
					collisionFunction = aabbAabbCollision
				end
			end
			
			if success then
				local restitution1 = collider1.restitution and collider1.restitution.val or 1
				local restitution2 = collider2.restitution and collider2.restitution.val or 1
				local restitution = math.min(restitution1, restitution2)
				
				collisions[#collisions + 1] = {collider1 = collider1, collider2 = collider2, direction = direction, distance = distancem, restitution = restitution}
				numCollisions[collider1] = numCollisions[collider1] and numCollisions[collider1] + 1 or 1
				numCollisions[collider2] = numCollisions[collider2] and numCollisions[collider2] + 1 or 1
			end
		end
	end
	
	for _, collider in ipairs(self.colliders) do
		collider.velocity.nextVal = collider.velocity.val
	end
	
	-- For order independence we will use velocity.val when getting and velocity.nextVal when setting
	for _, collision in ipairs(collisions) do
		local direction = collision.direction
		local collider1, collider2 = collision.collider1, collision.collider2
		local velocityDifference = collider2.velocity.val - collider1.velocity.val
		local impactSpeed = vec3.dot(velocityDifference, direction)
		if impactSpeed > 0 then
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
			
			local n1 = numCollisions[collider1]
			local n2 = numCollisions[collider2]
			
			local restitution = collision.restitution
			local speed1 = ((1 + restitution) * m2 * impactSpeed) / (n1 * (m1 + m2))
			local speed1 = ((1 + restitution) * m1 * impactSpeed) / (n2 * (m1 + m2))
			
			collider1.velocity.nextVal = collider1.velocity.nextVal + direction * speed1
			collider2.velocity.nextVal = collider2.velocity.nextVal - direction * speed2
			local distance = collision.distance
			collider1.position.val = collider1.position.val + distance * direction * speed1 / impactSpeed
			collider2.position.val = collider2.position.val - distance * direction * speed2 / impactSpeed
		end
	end
	
	for _, collision in ipairs(staticCollisions) do
		local direction, collider = collision.direction, collision.collider
		local velocityDifference = -collider.velocity.val
		local impactSpeed = vec3.dot(velocityDifference, direction)
		if impactSpeed > 0 then
			local m1, m2 = collider.mass.val == math.huge and 1 or 0, 1
			local n1 = numCollisions[collider]
			local restitution = collision.restitution
			local speed = ((1 + restitution) * m2 * impactSpeed) / (n1 * (m1 + m2))
			collider.velocity.nextVal = collider.velocity.nextVal + direction * speed
			local distance = collision.distance
			collider.position.val = collider.position.val - distance * direction / n1
		end
	end
	
	for _, collider in ipairs(self.colliders) do
		collider.velocity.val, collider.velocity.nextVal = collider.velocity.nextVal
	end
end

function sphereSphereCollision(sphere1Position, sphere1Radius, sphere2Position, sphere2Radius)
	local radiusDistance = sphere1Radius + sphere2Radius
	local posDifference = sphere2Position - sphere1Position
	local centreDistance = #posDifference
	local direction = -posDifference / centreDistance -- Normalised negative posDifference
	
	if centreDistance < radiusDistance then
		return true, direction, centreDistance - sphereRadius
	end
end

local closestTrianglePoint
function sphereTriangleCollision(spherePosition, sphereRadius, triangleP1, triangleP2, triangleP3, triangleNormal, triangleDistance)
	local closest = closestTrianglePoint(spherePosition, triangleP1, triangleP2, triangleP3, triangleNormal, triangleDistance)
	local centreDistance = vec3.distance(spherePosition, closest)
	if centreDistance < sphereRadius then
		return true, triangleNormal, centreDistance - sphereRadius
	end
end

local closestPlanePoint, inTriangle, closestLinePoint
function closestTrianglePoint(p, a,b,c,n,d)
	local p = closestPlanePoint(p, d,n)
	if inTriangle(p, a,b,c) then
		return p
	end
	
	local d = closestLinePoint(p, a,b)
	local e = closestLinePoint(p, b,c)
	local f = closestLinePoint(p, c,a)
	
	local dDistSq = vec3.distance2(p, d)
	local eDistSq = vec3.distance2(p, e)
	local fDistSq = vec3.distance2(p, f)
	local min = math.min(dDistSq, eDistSq, fDistSq)
	if min == dDistSq then
		return d
	elseif min == eDistSq then
		return e
	else--if min == fDistSq then
		return f
	end
end

function closestPlanePoint(p, d,n)
	return p - n * (vec3.dot(p, n) - d)
end

function inTriangle(p, a,b,c)
	-- Triangle relative to point
	a, b, c = a - p, b - p, c - p
	-- u, v, w = normals of PBC PCA PAB
	local u, v, w = vec3.cross(b, c), vec3.cross(c, a), vec3.cross(a, b)
	
	-- Are the normals all facing the same direction?
	return vec3.dot(u, v) > 0 and vec3.dot(u, w) > 0
end


function closestLinePoint(p, a,b)
	local t = vec3.dot(p - a, b - a) / vec3.dot(b - a, b - a)
	t = math.max(0, math.min(1, t))
	return a + t * (b - a)
end

return physics

