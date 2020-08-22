local loadObj = require("assets.loadObj")

local function newAsset(path)	
	local albedoData = love.image.newImageData("assets/" .. path .. "/albedo.png")
	local emissionData = love.image.newImageData("assets/" .. path .. "/emission.png")
	assert(albedoData:getWidth() == emissionData:getWidth() and albedoData:getHeight() == emissionData:getHeight(), "Differing albedo and emission image dimensions for asset " .. path)
	local albedoEmissionData = love.image.newImageData(albedoData:getDimensions())
	albedoEmissionData:mapPixel(
		function(x, y)
			local r, g, b = albedoData:getPixel(x, y)
			local a = emissionData:getPixel(x, y)
			return r, g, b, a
		end
	)
	
	local normalData = love.image.newImageData("assets/" .. path .. "/normal.png")
	local ambientOcclusionData = love.image.newImageData("assets/" .. path .. "/ambientOcclusion.png")
	assert(normalData:getWidth() == ambientOcclusionData:getWidth() and normalData:getHeight() == ambientOcclusionData:getHeight(), "Differing normal and ambient occlusion image dimensions for asset " .. path)
	local normalAmbientOcclusionData = love.image.newImageData(normalData:getDimensions())
	normalAmbientOcclusionData:mapPixel(
		function(x, y)
			local r, g, b = normalData:getPixel(x, y)
			local a = ambientOcclusionData:getPixel(x, y)
			return r, g, b, a
		end
	)
	
	local roughnessData = love.image.newImageData("assets/" .. path .. "/roughness.png")
	local metalnessData = love.image.newImageData("assets/" .. path .. "/metalness.png")
	local dielectricF0Data = love.image.newImageData("assets/" .. path .. "/dielectricF0.png")
	assert(roughnessData:getWidth() == metalnessData:getWidth() and roughnessData:getWidth() == dielectricF0Data:getWidth() and roughnessData:getHeight() == metalnessData:getHeight() and roughnessData:getHeight() == dielectricF0Data:getHeight(), "Differing roughness/metalness/dielectric f0 image dimensions for asset " .. path)
	local roughnessMetalnessDielectricF0Data = love.image.newImageData(roughnessData:getDimensions())
	roughnessMetalnessDielectricF0Data:mapPixel(
		function(x, y)
			local r = roughnessData:getPixel(x, y)
			local g = metalnessData:getPixel(x, y)
			local b = dielectricF0Data:getPixel(x, y) -- divided by two to get 0 to 2
			
			return r, g, b, 0
		end
	)
	
	return {
		mesh = loadObj("assets/" .. path .. "/mesh.obj"),
		albedoEmission = love.graphics.newImage(albedoEmissionData),
		normalAmbientOcclusion = love.graphics.newImage(normalAmbientOcclusionData),
		roughnessMetalnessDielectricF0 = love.graphics.newImage(roughnessMetalnessDielectricF0Data)
	}
end

return {
	boi = newAsset("boi")
}
