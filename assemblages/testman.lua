return function(e, px,py,pz, ox,oy,oz,ow)
	e:
		give("position", px, py, pz):
		give("drawable", "ball"):
		give("thrusters", 1500,1000,1000,1000,1500,1500,100,100,150,150,50,50):
		-- give("legs", 2, 1750, 1.5):
		give("guns", 0, -0.5, 1.2, 10, 0.5, 0.10, "bullet"):
		give("will"):
		give("velocity"):
		give("angularVelocity"):
		give("orientation", ox, oy, oz, ow):
		give("presence", "sphere", 1):
		give("mass", 100):
		give("restitution", 0.8):
		give("drag", 0.4)
end
