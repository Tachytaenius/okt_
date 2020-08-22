return component("presence", function(c, type, ...)
	c.type = type
	if type == "sphere" then
		c.radius = select(1, ...)
	end
	-- TODO
end)
