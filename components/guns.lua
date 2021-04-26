return component("guns", function(c, muzzleX, muzzleY, muzzleZ, speed, spreadAngle, fireRate, projectile)
	c.muzzlePos = vec3(muzzleX, muzzleY, muzzleZ)
	c.speed = speed
	c.spreadAngle = spreadAngle
	c.fireRate = fireRate
	c.projectile = projectile -- the name of an assemblage (needs to have velocity and position at least)
	
	c.cooldown = 0
end)
