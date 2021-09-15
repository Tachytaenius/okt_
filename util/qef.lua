local function distToPlane2(x,y,z,px,py,pz,pnx,pny,pnz)
	-- Look mate, WolframAlpha is your friend
	local a, b, c = x-px, y-py, z-pz
	return (math.abs(a+b+c)/math.sqrt(a^2+b^2+c^2))^2
end

local function getQef(x,y,z,edges)
	local ret = 0
	for _, edge in ipairs(edges) do
		ret = ret + distToPlane2(x,y,z,edge.x,edge.y,edge.z,edge.nx,edge.ny,edge.nz)
	end
	return ret
end

local function qefSolver(this,south,east,up)
	local edges = {}
	
	do
		local vep = this.vEdgePos
		if vep then
			edges[#edges+1]={x=0,y=vep, nx=this.vNormalX,ny=this.vNormalY}
		end
	end
	
	if east then
		local vep = east.vEdgePos
		if vep then
			edges[#edges+1]={x=1,y=vep, nx=east.vNormalX,ny=east.vNormalY}
		end
	end
	
	do
		local hep = this.hEdgePos
		if hep then
			edges[#edges+1]={x=hep,y=0, nx=this.hNormalX,ny=this.hNormalY}
		end
	end
	
	if south then
		local hep = south.hEdgePos
		if hep then
			edges[#edges+1]={x=hep,y=1, nx=south.hNormalX,ny=south.hNormalY}
		end
	end
	
	local 
	
	if #edges == 0 then return end
	
	local least, leastX, leastY = math.huge, 0.5, 0.5
	for x = 0, 1, 0.01 do
		for y = 0, 1, 0.01 do
			local qef = getQef(x,y,edges)
			if qef < least then
				least = qef
				leastX, leastY = x, y
			end
		end
	end
	return leastX, leastY
end

return qefSolver
