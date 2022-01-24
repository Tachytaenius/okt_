-- NOTE: Match with unloadScene

local loadObj = require("util.loadObj")
local getMergedMaps = require("util.gfx.getMergedMaps")

return function(path, world)
	local sceneJson = json.decode(love.filesystem.read("assets/scene/" .. path .. "/info.json"))
	
	local mesh, vertices = loadObj("assets/scene/" .. path .. "/mesh.obj")
	
	world.rendering.levelMesh = mesh
	world.rendering.levelSkyTexture = love.graphics.newCubeImage("assets/scene/" .. path .. "/skybox.png")
	world.rendering.levelAlbedoEmissionMap, world.rendering.levelNormalAmbientOcclusionMap, world.rendering.levelRoughnessMetalnessDielectricF0Map = getMergedMaps("scene/" .. path)
	local a = sceneJson.ambientLight
	world.rendering.ambientLight = vec3(a.x, a.y, a.z)
	
	world.physics.levelTriangles = {}
	for i = 0, #vertices / 3 - 1 do
		local v1, v2, v3 = vertices[i*3+1], vertices[i*3+2], vertices[i*3+3]
		local p1 = vec3(v1[1], v1[2], v1[3])
		local p2 = vec3(v2[1], v2[2], v2[3])
		local p3 = vec3(v3[1], v3[2], v3[3])
	
		local triangleRestitution = 0.2 -- TEMP
	
		world.physics:addTriangle(p1, p2, p3, triangleRestitution)
	end
	
	local g = sceneJson.gravity
	world.movement.gravity = vec3(g.x, g.y, g.z)
end
