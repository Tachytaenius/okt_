local vfov, far, near = math.rad(90), 1000, 0.001 -- Settings?

local sendMat4, sendVec3, sendVec4 do
	local ffi_copy = require("ffi").copy
	local buffer = love.data.newByteData(64) -- 4*4 floats
	local address = buffer:getFFIPointer()
	
	function sendVec3(shader, uniform, vector)
		ffi_copy(address, vector, 12)
		shader:send(uniform, buffer)
	end
	
	function sendVec4(shader, uniform, vector)
		ffi_copy(address, vector, 16)
		shader:send(uniform, buffer)
	end
	
	function sendMat4(shader, uniform, matrix)
		ffi_copy(address, matrix, 64)
		shader:send(uniform, buffer)
	end
end

local settings = require("settings")
local assets = require("assets")

local rendering = system({cameras = {"camera", "position", "orientation"}, models = {"drawable", "position"}, lights = {"position", "emission"}})

local dummyData = love.image.newImageData(1, 1)
local dummy = love.graphics.newImage(dummyData)
local dummyCube = love.graphics.newCubeImage({dummyData, dummyData, dummyData, dummyData, dummyData, dummyData})

function rendering:init()
	self.width, self.height = settings.graphics.width, settings.graphics.height
	
	self.positionBuffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba16f"})
	self.normalBuffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba16f"})
	self.albedoBuffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba8"})
	self.roughnessMetalnessDielectricF0Buffer = love.graphics.newCanvas(self.width, self.height, {format = "rgba8"})
	self.lighting = love.graphics.newCanvas(self.width, self.height, {format = "rgba16f"})
	self.depthBuffer = love.graphics.newCanvas(self.width, self.height, {format = "depth32f", readable = true})
	self.bufferSetup = {
		self.positionBuffer, self.normalBuffer, self.albedoBuffer, self.roughnessMetalnessDielectricF0Buffer, self.lighting,
		depthstencil = self.depthBuffer
	}
	
	self.output = love.graphics.newCanvas(self.width, self.height)
	
	self.bufferShader = love.graphics.newShader("shaders/gBufferAndAmbience.glsl")
	self.lightingShader = love.graphics.newShader("shaders/lighting.glsl")
	self.postProcessingShader = love.graphics.newShader("shaders/postProcess.glsl")
	
	-- levelSkyTexture, levelMesh, levelAlbedoEmissionMap, levelNormalAmbientOcclusionMap, levelRoughnessMetalnessDielectricF0Map
end

function rendering:draw(lerp, deltaDrawTime)
	local cameraEntity = self.cameras[1]
	if not cameraEntity then return end
	local cameraComponent = cameraEntity.camera
	local hideCameraEntity = not cameraComponent.show
	
	love.graphics.push("all")
	
	love.graphics.setShader(self.bufferShader)
	love.graphics.setCanvas(self.bufferSetup)
	love.graphics.clear()
	love.graphics.setBlendMode("replace", "premultiplied")
	
	local aspect, vfov, far, near = self.width / self.height, vfov, far, near
	local projectionMatrix = mat4.perspective(aspect, vfov, far, near)
	local cameraPosition, cameraOrientation
	-- TODO: Specific tracking types...?
	if cameraComponent.thirdPerson then
		cameraPosition = cameraEntity.position.ival + cameraComponent.offset
		cameraOrientation = cameraComponent.orientation
	else
		cameraPosition = cameraEntity.position.ival - vec3.rotate(cameraComponent.offset, -cameraEntity.orientation.ival)
		cameraOrientation = cameraEntity.orientation.ival * cameraComponent.orientation
	end
	local cameraMatrix = mat4.camera(cameraPosition, cameraOrientation)
	
	local id = 0 -- Gets stored in the alpha channel of the lighting map to differentiate objects from the sky and each other
	
	-- Draw the level first, if there is one
	if self.levelMesh then
		sendMat4(self.bufferShader, "modelToWorld", mat4())
		sendMat4(self.bufferShader, "modelToScreen", projectionMatrix * cameraMatrix)
		self.bufferShader:send("albedoEmissionMap", self.levelAlbedoEmissionMap)
		self.bufferShader:send("normalAmbientOcclusionMap", self.levelNormalAmbientOcclusionMap)
		self.bufferShader:send("roughnessMetalnessDielectricF0Map", self.levelRoughnessMetalnessDielectricF0Map)
		id = id + 1
		self.bufferShader:send("id", id)
		love.graphics.draw(self.levelMesh)
	end
	for _, e in ipairs(self.models) do
		if not (hideCameraEntity and e == cameraEntity) then -- if hideCameraEntity and e == cameraEntity then continue end >:(
			local modelMatrix = mat4.transform(e.position.ival, e.orientation and e.orientation.ival or quat())
			sendMat4(self.bufferShader, "modelToWorld", modelMatrix)
			sendMat4(self.bufferShader, "modelToScreen", projectionMatrix * cameraMatrix * modelMatrix)
			local asset = assets.getAsset(e.drawable)
			self.bufferShader:send("albedoEmissionMap", asset.albedoEmissionMap)
			self.bufferShader:send("normalAmbientOcclusionMap", asset.normalAmbientOcclusionMap)
			self.bufferShader:send("roughnessMetalnessDielectricF0Map", asset.roughnessMetalnessDielectricF0Map)
			id = id + 1
			self.bufferShader:send("id", id)
			love.graphics.draw(asset.mesh)
		end
	end
	
	love.graphics.setShader(self.lightingShader)
	love.graphics.setCanvas(self.lighting)
	love.graphics.setBlendMode("add", "premultiplied")
	self.lightingShader:send("windowSize", {self.width, self.height})
	-- self.lightingShader:send("farPlane", far)
	-- self.lightingShader:send("nearPlane", near)
	self.lightingShader:send("positionBuffer", self.positionBuffer)
	self.lightingShader:send("normalBuffer", self.normalBuffer)
	self.lightingShader:send("albedoBuffer", self.albedoBuffer)
	self.lightingShader:send("roughnessMetalnessDielectricF0Buffer", self.roughnessMetalnessDielectricF0Buffer)
	-- self.lightingShader:send("depthBuffer", self.depthBuffer)
	sendVec3(self.lightingShader, "viewPosition", cameraPosition)
	for _, e in ipairs(self.lights) do
		sendVec3(self.lightingShader, "lightColour", e.emission.ival)
		sendVec3(self.lightingShader, "lightPosition", e.position.ival)
		-- TODO
		local lightInfluenceX, lightInfluenceY, lightInfluenceW, lightInfluenceH = 0, 0, self.width, self.height
		love.graphics.draw(dummy, lightInfluenceX, lightInfluenceY, 0, lightInfluenceW, lightInfluenceH)
	end
	
	love.graphics.setShader(self.postProcessingShader)
	self.postProcessingShader:send("sky", self.levelSkyTexture or dummyCube)
	self.postProcessingShader:send("fovScale", math.tan(vfov/2))
	self.postProcessingShader:send("aspect", aspect)
	sendVec4(self.postProcessingShader, "viewQuaternion", cameraOrientation)
	love.graphics.setCanvas(self.output)
	-- love.graphics.clear()
	love.graphics.setBlendMode("replace")
	
	love.graphics.draw(self.lighting)
	
	love.graphics.pop()
end

return rendering
