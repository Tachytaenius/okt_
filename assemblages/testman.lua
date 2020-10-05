return function(e, px,py,pz, ox,oy,oz,ow)
	e:
		give("position", px, py, pz):
		give("drawable", "ball"):
		give("thrusters", 15,10,10,10,15,15,1,1,1.5,1.5,0.5,0.5):
		give("will"):
		give("velocity"):
		give("angularVelocity"):
		give("orientation", ox, oy, oz, ow):
		give("presence", "sphere", 1):
		give("mass", 100)
end
