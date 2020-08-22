return function(e, px,py,pz, ox,oy,oz,ow)
	e:
		give("position", px, py, pz):
		give("drawable", "boi"):
		give("thrusters", 50,30,20,20,30,30,1,1,1.5,1.5,0.5,0.5):
		give("will"):
		give("velocity"):
		give("angularVelocity"):
		give("orientation", ox, oy, oz, ow):
		give("presence", "sphere", 1.5):
		give("mass", 100)
end
