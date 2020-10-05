local setTangentsAndBitangents = require("util.setTangentsAndBitangents")

local terrain = system({})

function terrain:init(world)
	self.cw, self.ch, self.cd = world.chunkWidth, world.chunkHeight, world.chunkDepth
	self.chunks = {}
	self.chunksToUpdate = {}
	for x = -5, 5 do
		for y = -5, 5 do
			for z = -5, 5 do
				self.chunksToUpdate[#self.chunksToUpdate + 1] = self:generate(x, y, z)
			end
		end
	end
end

function terrain:update(dt)
	self:updateMeshes()
	self.chunksToUpdate = {}
end	

function terrain:getChunk(x, y, z)
	local xTable = self.chunks[x]
	if not xTable then return end
	local xyTable = xTable[y]
	if not xyTable then return end
	return xyTable[z]
end

function terrain:setChunk(x, y, z, chunk)
	local xTable = self.chunks[x]
	if not xTable then
		xTable = {}
		self.chunks[x] = xTable
	end
	local xyTable = xTable[y]
	if not xyTable then
		xyTable = {}
		xTable[y] = xyTable
	end
	xyTable[z] = chunk
end

function terrain:getIndex(x, y, z)
	return x + y*self.cw + z*self.cw*self.ch + 1
end

function terrain:getVoxel(x, y, z)
	local cx, cy, cz =
		math.floor(x / self.cw),
		math.floor(y / self.ch),
		math.floor(z / self.cd)
	local chunk = self:getChunk(cx, cy, cz)
	if not chunk then
		return 0
	end
	local vx, vy, vz =
		x % self.cw,
		y % self.ch,
		z % self.cd
	return self:getLocalVoxel(chunk, vx, vy, vz)
end

function terrain:getLocalVoxel(chunk, x, y, z)
	local i = self:getIndex(x, y, z)
	return string.byte(chunk.voxels:sub(i, i)), (string.byte(chunk.normalsX:sub(i, i)) / 255) * 2 - 1, (string.byte(chunk.normalsY:sub(i, i)) / 255) * 2 - 1, (string.byte(chunk.normalsZ:sub(i, i)) / 255) * 2 - 1
end

function terrain:updateMeshes(dt)
	local regionX, regionY, regionZ, regionX2, regionY2, regionZ2 = math.huge, math.huge, math.huge, -math.huge, -math.huge, -math.huge
	for _, chunk in ipairs(self.chunksToUpdate) do
		regionX, regionY, regionZ = math.min(regionX, chunk.x), math.min(regionY, chunk.y), math.min(regionZ, chunk.z)
		regionX2, regionY2, regionZ2 = math.max(regionX2, chunk.x), math.max(regionY2, chunk.y), math.max(regionZ2, chunk.z)
	end
	regionW, regionH, regionD = regionX2 - regionX + 1, regionY2 - regionY + 1, regionZ2 - regionZ + 1
	regionX, regionY, regionZ, regionW, regionH, regionD = regionX * self.cw, regionY * self.ch, regionZ * self.cd, regionW * self.cw, regionH * self.ch, regionD * self.cd
	regionX, regionY, regionZ, regionW, regionH, regionD = regionX - 1, regionY - 1, regionZ - 1, regionW + 2, regionH + 2, regionD + 2
	
	local function getRegionIndex(x, y, z) -- TODO rename to hash
		return (x-regionX) + (y-regionY)*regionW + (z-regionZ)*regionW*regionH
	end
	
	local cellVertices = {}
	-- TODO: SEE PLANES!
	for _, chunk in ipairs(self.chunksToUpdate) do
		local ox, oy, oz = chunk.x * self.cw, chunk.y * self.ch, chunk.z * self.cd -- offset
	
		for x = 0, self.cw - 1 do
			for y = 0, self.ch - 1 do
				for z = 0, self.cd - 1 do
					local gx, gy, gz = x + ox, y + oy, z + oz -- global
					
					-- Variable names: negative, positive; x, y, z
					local nnn, nx, ny, nz = self:getVoxel(gx, gy, gz)
					local nnp = self:getVoxel(gx, gy, gz+1)
					local npn = self:getVoxel(gx, gy+1, gz)
					local npp = self:getVoxel(gx, gy+1, gz+1)
					local pnn = self:getVoxel(gx+1, gy, gz)
					local pnp = self:getVoxel(gx+1, gy, gz+1)
					local ppn = self:getVoxel(gx+1, gy+1, gz)
					local ppp = self:getVoxel(gx+1, gy+1, gz+1)
					
					local centreWeight = 0.1
					local sumWeights = nnn+nnp+npn+npp+pnn+pnp+ppn+ppp+centreWeight
					local vx = (gx * (nnn+nnp+npn+npp) + (gx + 1) * (pnn+pnp+ppn+ppp) + (gx + 0.5) * centreWeight) / sumWeights
					local vy = (gy * (nnn+nnp+pnn+pnp) + (gy + 1) * (npn+npp+ppn+ppp) + (gy + 0.5) * centreWeight) / sumWeights
					local vz = (gz * (nnn+npn+pnn+ppn) + (gz + 1) * (nnp+npp+pnp+ppp) + (gz + 0.5) * centreWeight) / sumWeights
					local l = vec3.normalize(vec3(nx, ny, nz))
					cellVertices[getRegionIndex(gx, gy, gz)] = {vx, vy, vz, math.random(), math.random(), l.x, l.y, l.z}
				end
			end
		end
	end
	
	for _, chunk in ipairs(self.chunksToUpdate) do
		local meshVertices = {}
		local ox, oy, oz = chunk.x * self.cw, chunk.y * self.ch, chunk.z * self.cd -- offset
		for x = 0, self.cw - 1 do
			for y = 0, self.ch - 1 do
				for z = 0, self.cd - 1 do
					local gx, gy, gz = x + ox, y + oy, z + oz -- global
					
					local a = self:getVoxel(gx, gy, gz) > 0
					
					local function writeEdge(v1, v2, v3, v4)
						if not a then -- If it's not the sample in the negative direction that's solid, then swap the winding order of the vertices (face culling)
							v2, v3 = v3, v2
						end
						
						if not (v1 and v2 and v3 and v4) then
							return
						end
						
						-- meshVertices[#meshVertices+1] = v1
						-- meshVertices[#meshVertices+1] = v1
						-- meshVertices[#meshVertices+1] = v2
						-- 
						-- meshVertices[#meshVertices+1] = v2
						-- meshVertices[#meshVertices+1] = v2
						-- meshVertices[#meshVertices+1] = v4
						-- 
						-- meshVertices[#meshVertices+1] = v3
						-- meshVertices[#meshVertices+1] = v3
						-- meshVertices[#meshVertices+1] = v1
						-- 
						-- meshVertices[#meshVertices+1] = v4
						-- meshVertices[#meshVertices+1] = v4
						-- meshVertices[#meshVertices+1] = v3
						
						meshVertices[#meshVertices+1] = v1
						meshVertices[#meshVertices+1] = v2
						meshVertices[#meshVertices+1] = v3
						
						meshVertices[#meshVertices+1] = v3
						meshVertices[#meshVertices+1] = v2
						meshVertices[#meshVertices+1] = v4
					end
					
					local b = self:getVoxel(gx+1, gy, gz) > 0
					if a ~= b then
						local v1 = cellVertices[getRegionIndex(gx, gy-1, gz-1)]
						local v2 = cellVertices[getRegionIndex(gx, gy-1, gz  )]
						local v3 = cellVertices[getRegionIndex(gx, gy,   gz-1)]
						local v4 = cellVertices[getRegionIndex(gx, gy,   gz  )]
						writeEdge(v1, v2, v3, v4)
					end
					
					local b = self:getVoxel(gx, gy+1, gz) > 0
					if a ~= b then
						local v1 = cellVertices[getRegionIndex(gx-1, gy, gz-1)]
						local v2 = cellVertices[getRegionIndex(gx  , gy, gz-1)]
						local v3 = cellVertices[getRegionIndex(gx-1, gy, gz  )]
						local v4 = cellVertices[getRegionIndex(gx,   gy, gz  )]
						writeEdge(v1, v2, v3, v4)
					end
					
					local b = self:getVoxel(gx, gy, gz+1) > 0
					if a ~= b then
						local v1 = cellVertices[getRegionIndex(gx-1, gy-1, gz)]
						local v2 = cellVertices[getRegionIndex(gx-1, gy,   gz)]
						local v3 = cellVertices[getRegionIndex(gx,   gy-1, gz)]
						local v4 = cellVertices[getRegionIndex(gx,   gy,   gz)]
						writeEdge(v1, v2, v3, v4)
					end
					
				end
			end
		end
		
		if chunk.mesh then
			chunk.mesh:release()
		end
		if #meshVertices > 0 then
			setTangentsAndBitangents(meshVertices)
			chunk.mesh = love.graphics.newMesh(consts.vertexFormat, meshVertices, "triangles")
		end
	end
end

local temporaryTerrainTable = {}
local temporaryNormalXTable = {}
local temporaryNormalYTable = {}
local temporaryNormalZTable = {}
function terrain:generate(x, y, z)
	local noiser = self:getWorld().simplexer
	
	local chunk = {x = x, y = y, z = z}
	local ox, oy, oz = chunk.x * self.cw, chunk.y * self.ch, chunk.z * self.cd -- offset
	for x = 0, self.cw - 1 do
		for y = 0, self.ch - 1 do
			local gx, gy = x + ox, y + oy
			local height = 2.5 + 3 * noiser:noise2D(gx / 8, gy / 8)
			
			local surfaceNormalX, surfaceNormalY, surfaceNormalZ
			local N = 2.5 + 3 * noiser:noise2D(gx / 8, (gy + 1) / 8)
			local S = 2.5 + 3 * noiser:noise2D(gx / 8, (gy - 1) / 8)
			local E = 2.5 + 3 * noiser:noise2D((gx + 1) / 8, gy / 8)
			local W = 2.5 + 3 * noiser:noise2D((gx - 1) / 8, gy / 8)
			
			-- local n = vec3(gx, gy - 1, S)
			-- local e = vec3(gx, gy + 1, N)
			-- local s = vec3(gx + 1, gy, E)
			-- local w = vec3(gx - 1, gy, W)
			
			local vec = vec3.normalize(vec3(2*(E-W),2*(S-N),-4))
			
			surfaceNormalX = vec.x
			surfaceNormalY = vec.y
			surfaceNormalZ = vec.z
			
			for z = 0, self.cd - 1 do
				local gz = z + oz -- global
				local index = self:getIndex(x, y, z)
				local terrainValue, normalXValue, normalYValue, normalZValue
				if gz <= height then
					terrainValue = 1
				else
					terrainValue = 0
				end
				if height - 2 <= gz and gz <= height + 1 then
					normalXValue, normalYValue, normalZValue = surfaceNormalX, surfaceNormalY, surfaceNormalZ
				else
					normalXValue, normalYValue, normalZValue = 0, 0, 0 -- dont cares
				end
				temporaryTerrainTable[index] = string.char(terrainValue)
				temporaryNormalXTable[index] = string.char((normalXValue / 2 + 0.5)*255)
				temporaryNormalYTable[index] = string.char((normalYValue / 2 + 0.5)*255)
				temporaryNormalZTable[index] = string.char((normalZValue / 2 + 0.5)*255)
			end
		end
	end
	temporaryTerrainTable[self.cw * self.ch * self.cd + 1] = nil
	chunk.voxels = table.concat(temporaryTerrainTable)
	temporaryNormalXTable[self.cw * self.ch * self.cd + 1] = nil
	chunk.normalsX = table.concat(temporaryNormalXTable)
	temporaryNormalYTable[self.cw * self.ch * self.cd + 1] = nil
	chunk.normalsY = table.concat(temporaryNormalYTable)
	temporaryNormalZTable[self.cw * self.ch * self.cd + 1] = nil
	chunk.normalsZ = table.concat(temporaryNormalZTable)
	
	self:setChunk(x, y, z, chunk)
	
	return chunk -- TEMP?
end

return terrain
