-- Combine individual maps like metalness and roughness into single images for use in shaders

return function(path)
	-- For each combined map:
	-- Get the individual maps as ImageData
	-- assert that the dimensions are the same
	-- Make a new ImageData for the output map
	-- Use mapPixel to combine them
	
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
			local b = dielectricF0Data:getPixel(x, y)
			
			return r, g, b, 0
		end
	)
	
	return love.graphics.newImage(albedoEmissionData), love.graphics.newImage(normalAmbientOcclusionData), love.graphics.newImage(roughnessMetalnessDielectricF0Data)
end