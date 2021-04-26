return component("presence", function(c, type, ...)
	c.type = type
	if type == "sphere" then
		c.radius = select(1, ...)
	elseif type == "point" then
		-- TEMP, I guess?
		c.type = "sphere"
		c.radius = 0
	else
		error("Unknown presence type " .. type)
	end
end)
