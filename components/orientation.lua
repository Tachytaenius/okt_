return component("orientation", function(c, x, y, z, w)
	c.val = quat(x, y, z, w)
end)
