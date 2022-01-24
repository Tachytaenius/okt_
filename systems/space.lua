local space = system({objects = {"presence", "position"}})

function space:init()
	self.hash = {}
end

-- TODO: octrees and stuff.

return space
