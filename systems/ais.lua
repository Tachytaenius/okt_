local ais = system({pool = {"will", "ai"}})

function ais:update()
	for _, e in ipairs(self.pool) do
		-- TODO, obviously
		e.will.translate = nil
		e.will.rotate = nil
	end
end

return ais
