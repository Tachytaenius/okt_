return component("presence", function(c, type, ...)
	c.type = type
	if type == "sphere" then
		c.radius = select(1, ...)
	elseif type == "aabb" then
		c.xRadius = select(1, ...)
		c.yRadius = select(2, ...)
		c.zRadius = select(3, ...)
	else
		error("Unknown presence type " .. type)
	end
end)
