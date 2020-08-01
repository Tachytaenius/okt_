local slerpPools = 2
local quantities = system({
	orientation = {"orientation"},
	angularVelocity = {"angularVelocity"}, position = {"position"}, velocity = {"velocity"}, emission = {"emission"}, ambience = {"ambience"}
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
	lerpPool(self.angularVelocity)
	lerpPool(self.position)
	lerpPool(self.velocity)
	lerpPool(self.emission)
	lerpPool(self.ambience)
end

return quantities
