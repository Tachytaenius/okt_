return function(renderingSystem, physicsSystem)
	renderingSystem.levelMesh = nil
	renderingSystem.levelSkyTexture = nil
	renderingSystem.levelAlbedoEmissionMap, renderingSystem.levelNormalAmbientOcclusionMap, renderingSystem.levelRoughnessMetalnessDielectricF0Map = nil
	
	physicsSystem.levelTriangles = {}
end
