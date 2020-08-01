local sendMat4, sendVec3 do
	local ffi_copy = require("ffi").copy
	local buffer = love.data.newByteData(64) -- 4*4 floats
	local address = buffer:getFFIPointer()
	
	function sendMat4(shader, uniform, matrix)
		ffi_copy(address, matrix, 64)
		shader:send(uniform, buffer)
	end
	
	function sendVec3(shader, uniform, vector)
		ffi_copy(address, vector, 12)
		shader:send(uniform, buffer)
	end
end

local settings = require("settings")
local assets = require("assets")

local rendering = system({cameras = {"camera", "position", "orientation"}, models = {"drawable", "position", "orientation"}, lights = {"position", "emission"}})

local dummy = love.graphics.newImage(love.image.newImageData(1, 1))

function rendering:init(world)
	self.width, self.height = settings.graphics.width, settings.graphics.height
	
	self.positionNormalBuffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba16f"})
	self.albedoRoughnessMetalnessBuffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba8"})
	self.velocityDielectricF0Buffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba16f"})
	self.lighting = love.graphics.newCanvas(self.width, self.height, {format = "rgba16f"})
	self.depthBuffer = love.graphics.newCanvas(self.width, self.height, {format = "depth32f", readable = true})
	self.bufferSetup = {
		self.positionNormalBuffer, self.albedoRoughnessMetalnessBuffer, self.velocityDielectricF0Buffer, self.lighting,
		depthstencil = self.depthBuffer
	}
	self.output = love.graphics.newCanvas(self.width, self.height)
	self.bufferShader = love.graphics.newShader("shaders/gBufferAndAmbience.glsl")
	self.lightingShader = love.graphics.newShader("shaders/lighting.glsl")
end

function rendering:draw(lerp)
	local camera = self.cameras[1]
	if not camera then return end
	
	love.graphics.push("all")
	
	love.graphics.setShader(self.bufferShader)
	love.graphics.setCanvas(self.bufferSetup)
	love.graphics.clear()
	love.graphics.setBlendMode("replace", "premultiplied")
	
	local far, near = 10, 0.1
	local projectionMatrix = mat4.perspective(self.width / self.height, math.rad(90), far, near)
	local cameraMatrix = mat4.camera(camera.position.ival, camera.orientation.ival)
	
	for _, e in ipairs(self.models) do
		if e ~= camera then -- if e == camera then continue end >:(
			local modelMatrix = mat4.transform(e.position.ival, e.orientation.ival)
			-- sendMat4(self.bufferShader, "modelToWorld", modelMatrix)
			sendMat4(self.bufferShader, "modelToCamera", cameraMatrix * modelMatrix)
			sendMat4(self.bufferShader, "modelToScreen", projectionMatrix * cameraMatrix * modelMatrix)
			local asset = assets[e.drawable.asset]
			self.bufferShader:send("albedoEmissionMap", asset.albedoEmission)
			self.bufferShader:send("normalAmbientOcclusionMap", asset.normalAmbientOcclusion)
			self.bufferShader:send("roughnessMetalnessDielectricF0Map", asset.roughnessMetalnessDielectricF0)
			love.graphics.draw(asset.mesh)
		end
	end
	
	love.graphics.setShader(self.lightingShader)
	love.graphics.setCanvas(self.lighting)
	love.graphics.setBlendMode("add", "premultiplied")
	self.lightingShader:send("windowSize", {self.width, self.height})
	self.lightingShader:send("farPlane", far)
	self.lightingShader:send("nearPlane", near)
	self.lightingShader:send("positionNormalBuffer", self.positionNormalBuffer)
	self.lightingShader:send("albedoRoughnessMetalnessBuffer", self.albedoRoughnessMetalnessBuffer)
	self.lightingShader:send("velocityDielectricF0Buffer", self.velocityDielectricF0Buffer)
	self.lightingShader:send("depthBuffer", self.depthBuffer)
	for _, e in ipairs(self.lights) do
		sendVec3(self.lightingShader, "lightColour", e.emission.ival)
		sendVec3(self.lightingShader, "lightPosition", cameraMatrix * e.position.ival)
		-- TODO
		local lightInfluenceX, lightInfluenceY, lightInfluenceW, lightInfluenceH = 0, 0, self.width, self.height
		love.graphics.draw(dummy, lightInfluenceX, lightInfluenceY, 0, lightInfluenceW, lightInfluenceH)
	end
	
	love.graphics.setShader(self.postProcessingShader)
	love.graphics.setCanvas(self.output)
	-- love.graphics.clear()
	love.graphics.setBlendMode("replace")
	love.graphics.draw(self.lighting)
	
	love.graphics.pop()
end

return rendering