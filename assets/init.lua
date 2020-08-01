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
			-- roughness-metalness storage pattern is rrrrrrrm
			local roughness = roughnessData:getPixel(x, y)
			local metalness = metalnessData:getPixel(x, y)
			local rr = math.floor(roughness * 255) - math.floor(roughness * 255) % 2
			local rm = metalness > 0.5 and 1 or 0
			
			local fr, fg = dielectricF0Data:getPixel(x, y)
			-- local f = fg > 0.5 and 1 / fr or fr
			
			local r = (rr + rm) / 255
			local g = fg > 0.5 and 0.5 + (1 - fr) / 2 or fr / 2 -- two-channel 0 to inf mode --> one-channel 0 to inf mode
			
			return r, g, 1, 1
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
