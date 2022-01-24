-- NOTE: Match with loadScene

return function(world)
	world.rendering.levelMesh = nil
	world.rendering.levelSkyTexture = nil
	world.rendering.levelAlbedoEmissionMap, world.rendering.levelNormalAmbientOcclusionMap, world.rendering.levelRoughnessMetalnessDielectricF0Map = nil
	
	world.rendering.ambientLight = nil
	
	world.physics.levelTriangles = {}
	
	world.movement.gravity = nil
end
