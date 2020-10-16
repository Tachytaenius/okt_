local slerpPools = 2
local quantities = system({
	orientation = {"orientation"}, -- Uses slerp
	position = {"position"}, emission = {"emission"}, ambience = {"ambience"}, gravity = {"gravity"} -- Uses lerp
	-- velocity = {"velocity"}, angularVelocity = {"angularVelocity"}, restitution = {"restitution"} -- unused lerp
})

function quantities:update(dt)
	-- Iterate over all entities with component X and set its "previous value" to the current one
	for _, pool in ipairs(self.__pools) do
		local component = pool.__name -- pool.__filter[1].__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.pval = bag.val
		end
	end
end

function quantities:draw(lerp)
	local function slerpPool(pool)
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.ival = quat.slerp(bag.pval, bag.val, lerp)
		end
	end
	
	local function lerpPool(pool)
		local component = pool.__name
		for _, e in ipairs(pool) do
			local bag = e:get(component)
			bag.ival = bag.pval * (1 - lerp) + bag.val * lerp
		end
	end
	
	slerpPool(self.orientation)
	lerpPool(self.position)
	lerpPool(self.emission)
	lerpPool(self.ambience)
	lerpPool(self.gravity)
	-- lerpPool(self.velocity)
	-- lerpPool(self.angularVelocity)
	-- lerpPool(self.restitution)
end

return quantities
