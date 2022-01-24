local lrq = require("util.largestRootQuadratic")

local ais = system({pool = {"will", "ai"}})

function ais:update()
	for _, e in ipairs(self.pool) do
		if e.ai.target and e.ai.guns then
			local g = self:getWorld().gravity or vec3()
			local ep = e.position.val
			local ev = e.velocity.val
			local tp = e.ai.target.position.val
			local tv = e.ai.target.velocity.val
			local s = e.guns.shotSpeed
			
			local p = tp - ep
			local v = tv - ev
			
			local a = s*s - vec2.dot(v, v)
			local b = -2 * vec2.dot(v, p)
			local c = vec2.dot(-p, p)
			
			local shootTo = v * lrq(a, b, c)
			
			e.will.shoot = shootTo
		else
			e.will.translate = nil
			e.will.rotate = nil
			e.will.shoot = nil
		end
	end
end

return ais
