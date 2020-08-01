return component("thrusters", function(c, forward, backwards, left, right, up, down, pitchUp, pitchDown, rollLeft, rollRight, yawLeft, yawRight)
	-- Store the strengths thereof
	c.forward,  c.backwards = forward,  backwards
	c.left,     c.right     = left,     right
	c.up,       c.down      = up,       down
	c.pitchUp,  c.pitchDown = pitchUp,  pitchDown
	c.rollLeft, c.rollRight = rollLeft, rollRight
	c.yawLeft,  c.yawRight  = yawLeft,  yawRight
end)
