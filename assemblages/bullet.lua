return function(e)
	e
		:give("position")
		-- :give("tracerColour", 1, 1, 0)
		:give("model", "bullet")
		:give("velocity")
		-- :give("presence", "point")
		:give("mass", 1)
		:give("restitution", 0.05)
		:give("drag", 0.01)
		
		-- it could have been tracers... *sigh*
		:give("orientation")
end
