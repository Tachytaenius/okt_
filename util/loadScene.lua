local loadObj = require("util.loadObj")
local getMergedMaps = require("util.gfx.getMergedMaps")

return function(path, renderingSystem, physicsSystem)
	local mesh, vertices = loadObj("assets/scene/" .. path .. "/mesh.obj")
	
	renderingSystem.levelMesh = mesh
	renderingSystem.levelSkyTexture = love.graphics.newCubeImage("assets/scene/" .. path .. "/skybox.png")
	renderingSystem.levelAlbedoEmissionMap, renderingSystem.levelNormalAmbientOcclusionMap, renderingSystem.levelRoughnessMetalnessDielectricF0Map = getMergedMaps("scene/" .. path)
	
	-- physicsSystem.levelTriangles = {}
	-- for i = 0, #vertices / 3 - 1 do
	-- 	local v1, v2, v3 = vertices[i*3+1], vertices[i*3+2], vertices[i*3+3]
	-- 	local p1 = vec3(v1[1], v1[2], v1[3])
	-- 	local p2 = vec3(v2[1], v2[2], v2[3])
	-- 	local p3 = vec3(v3[1], v3[2], v3[3])
	-- 
	-- 	local triangleRestitution = 0.2 -- TEMP
	-- 
	-- 	physicsSystem:addTriangle(p1, p2, p3, triangleRestitution)
	-- end
end
