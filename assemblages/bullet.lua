return function(e)
	e:
		give("position"):
		give("drawable", "ball"):
		give("velocity"):
		-- give("presence", "point"):
		give("mass", 100):
		give("restitution", 0.05):
		give("drag", 0.1)
end
