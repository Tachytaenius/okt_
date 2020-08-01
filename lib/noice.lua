local noice = {
	name = "Noice",
	description = "OpenSimplex and Perlin noise in LuaJIT",
	credits = "OpenSimplex is a port of https://github.com/lmas/opensimplex/",
	author = "Tachytaenius"
}

local function lerp(a, b, i)
	return a * (1 - i) + b * i
end

local function fade(x)
	return x*x*x*(x*(x*6-15)+10)
end

local ffi = require("ffi")
local uint64 = ffi.typeof("uint64_t")

local floor, sqrt, modf = math.floor, math.sqrt, math.modf

local stretchConstant2D = (1/sqrt(2+1)-1)/2
local squishConstant2D = (sqrt(2+1)-1)/2
local stretchConstant3D = (1/sqrt(3+1)-1)/3
local squishConstant3D = (sqrt(3+1)-1)/3
local stretchConstant3D = (1/sqrt(4+1)-1)/4
local squishConstant3D = (sqrt(4+1)-1)/4

local normConstant2D = 47
local normConstant3D = 103
local normConstant4D = 30

local gradients2D = { [0]=
     5,  2,    2,  5,
    -5,  2,   -2,  5,
     5, -2,    2, -5,
    -5, -2,   -2, -5
}

local gradients3D = { [0]=
    -11,  4,  4,   -4,  11,  4,   -4,  4,  11,
     11,  4,  4,    4,  11,  4,    4,  4,  11,
    -11, -4,  4,   -4, -11,  4,   -4, -4,  11,
     11, -4,  4,    4, -11,  4,    4, -4,  11,
    -11,  4, -4,   -4,  11, -4,   -4,  4, -11,
     11,  4, -4,    4,  11, -4,    4,  4, -11,
    -11, -4, -4,   -4, -11, -4,   -4, -4, -11,
     11, -4, -4,    4, -11, -4,    4, -4, -11
}
local lenGradients3D = #gradients3D+1

local gradients4D = { [0]=
     3,  1,  1,  1,    1,  3,  1,  1,    1,  1,  3,  1,    1,  1,  1,  3,
    -3,  1,  1,  1,   -1,  3,  1,  1,   -1,  1,  3,  1,   -1,  1,  1,  3,
     3, -1,  1,  1,    1, -3,  1,  1,    1, -1,  3,  1,    1, -1,  1,  3,
    -3, -1,  1,  1,   -1, -3,  1,  1,   -1, -1,  3,  1,   -1, -1,  1,  3,
     3,  1, -1,  1,    1,  3, -1,  1,    1,  1, -3,  1,    1,  1, -1,  3,
    -3,  1, -1,  1,   -1,  3, -1,  1,   -1,  1, -3,  1,   -1,  1, -1,  3,
     3, -1, -1,  1,    1, -3, -1,  1,    1, -1, -3,  1,    1, -1, -1,  3,
    -3, -1, -1,  1,   -1, -3, -1,  1,   -1, -1, -3,  1,   -1, -1, -1,  3,
     3,  1,  1, -1,    1,  3,  1, -1,    1,  1,  3, -1,    1,  1,  1, -3,
    -3,  1,  1, -1,   -1,  3,  1, -1,   -1,  1,  3, -1,   -1,  1,  1, -3,
     3, -1,  1, -1,    1, -3,  1, -1,    1, -1,  3, -1,    1, -1,  1, -3,
    -3, -1,  1, -1,   -1, -3,  1, -1,   -1, -1,  3, -1,   -1, -1,  1, -3,
     3,  1, -1, -1,    1,  3, -1, -1,    1,  1, -3, -1,    1,  1, -1, -3,
    -3,  1, -1, -1,   -1,  3, -1, -1,   -1,  1, -3, -1,   -1,  1, -1, -3,
     3, -1, -1, -1,    1, -3, -1, -1,    1, -1, -3, -1,    1, -1, -1, -3,
    -3, -1, -1, -1,   -1, -3, -1, -1,   -1, -1, -3, -1,   -1, -1, -1, -3
}

local simplexerMethods = {}

function simplexerMethods:init(seed)
	seed = seed or 0
	self.seed = seed
	self.perm, self.permGradIndex3D, self.source = {}, {}, {}
	for i = 0, 255 do
		self.perm[i] = 0
		self.permGradIndex3D[i] = 0
		self.source[i] = i
	end
	seed = uint64(seed)
	seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
	seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
	seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
	for i = 255, 0, -1 do
		seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
		local r = tonumber((seed + 31ULL) % (uint64(i) + 1ULL))
		if r < 0 then
			r = r + i + 1
		end
		self.perm[i] = self.source[r]
		self.permGradIndex3D[i] = (self.perm[i] % (lenGradients3D / 3)) * 3
		self.source[r] = self.source[i]
	end
end

function simplexerMethods:extrapolate2D(xsb, ysb, dx, dy)
	local perm = self.perm
	local index = floor((perm[(perm[xsb % 256] + ysb) % 256]) / 2) % 8 * 2
	local g1, g2 = gradients2D[index], gradients2D[index+1]
	return g1*dx+g2*dy
end

function simplexerMethods:noise2D(x, y)
	local stretchOffset = (x + y) * stretchConstant2D
	local xs = x + stretchOffset
	local ys = y + stretchOffset
	
	local xsb = floor(xs)
	local ysb = floor(ys)
	
	local squishOffset = (xsb + ysb) * squishConstant2D
	local xb = xsb + squishOffset
	local yb = ysb + squishOffset
	
	local xins = xs - xsb
	local yins = ys - ysb
	
	local inSum = xins + yins
	
	local dx0 = x - xb
	local dy0 = y - yb
	
	local value = 0
	
	local dx1 = dx0 - 1 - squishConstant2D
	local dy1 = dy0 - 0 - squishConstant2D
	local attn1 = 2 - dx1 * dx1 - dy1 * dy1
	if attn1 > 0 then
		attn1 = attn1 * attn1
		value = value + attn1 * attn1 * self:extrapolate2D(xsb + 1, ysb, dx1, dy1)
	end
	
	local dx2 = dx0 - 0 - squishConstant2D
	local dy2 = dy0 - 1 - squishConstant2D
	local attn2 = 2 - dx2 * dx2 - dy2 * dy2
	if attn2 > 0 then
		attn2 = attn2 * attn2
		value = value + attn2 * attn2 * self:extrapolate2D(xsb, ysb + 1, dx2, dy2)
	end
	
	local xsvExt, ysvExt, dxExt, dyExt
	if inSum <= 1 then
		zins = 1 - inSum
		if zins > xins or zins > yins then
			if xins > yins then
				xsvExt = xsb + 1
				ysvExt = ysb - 1
				dxExt = dx0 - 1
				dyExt = dy0 + 1
			else
				xsvExt = xsb - 1
				ysvExt = ysb + 1
				dxExt = dx0 + 1
				dyExt = dy0 - 1
			end
		else
			xsvExt = xsb + 1
			ysvExt = ysb + 1
			dxExt = dx0 - 1 - 2 * squishConstant2D
			dyExt = dy0 - 1 - 2 * squishConstant2D
		end
	else
		zins = 2 - inSum
		if zins < xins or zins < yins then
			if xins > yins then
				xsvExt = xsb + 2
				ysvExt = ysb + 0
				dxExt = dx0 - 2 - 2 * squishConstant2D
				dyExt = dy0 + 0 - 2 * squishConstant2D
			else
				xsvExt = xsb + 0
				ysvExt = ysb + 2
				dxExt = dx0 + 0 - 2 * squishConstant2D
				dyExt = dy0 - 2 - 2 * squishConstant2D
			end
		else
			dxExt = dx0
			dyExt = dy0
			xsvExt = xsb
			ysvExt = ysb
		end
		xsb = xsb + 1
		ysb = ysb + 1
		dx0 = dx0 - 1 - 2 * squishConstant2D
		dy0 = dy0 - 1 - 2 * squishConstant2D
	end
	
	local attn0 = 2 - dx0 * dx0 - dy0 * dy0
	if attn0 > 0 then
		attn0 = attn0 * attn0
		value = value + attn0 * attn0 * self:extrapolate2D(xsb, ysb, dx0, dy0)
	end
	
	local attnExt = 2 - dxExt * dxExt - dyExt * dyExt
	if attnExt > 0 then
		attnExt = attnExt * attnExt
		value = value + attnExt * attnExt * self:extrapolate2D(xsvExt, ysvExt, dxExt, dyExt)
	end
	
	return value / normConstant2D
end

function simplexerMethods:noise3D(x, y, z)
	error("NYI!")
end

function simplexerMethods:noise4D(x, y, z, w)
	error("NYI!")
end


local perlinerMethods = {}

function perlinerMethods:init(seed)
	seed = seed or 0
	self.seed = seed
	self.perm, self.permGradIndex3D, self.source = {}, {}, {}
	for i = 0, 255 do
		self.perm[i] = 0
		self.permGradIndex3D[i] = 0
		self.source[i] = i
	end
	seed = uint64(seed)
	seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
	seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
	seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
	for i = 255, 0, -1 do
		seed = seed * 6364136223846793005ULL + 1442695040888963407ULL
		local r = tonumber((seed + 31ULL) % (uint64(i) + 1ULL))
		if r < 0 then
			r = r + i + 1
		end
		self.perm[i] = self.source[r]
		self.permGradIndex3D[i] = (self.perm[i] % (lenGradients3D / 3)) * 3
		self.source[r] = self.source[i]
	end
end

function perlinerMethods:noise2D(x, y, w, h)
	local cellX, dx = modf(x)
	local cellY, dy = modf(y)
	
	dx = fade(dx)
	dy = fade(dy)
	
	local nn = self:extrapolate2D(cellX, cellY, x, y, w, h)
	local np = self:extrapolate2D(cellX, cellY + 1, x, y, w, h)
	local pn = self:extrapolate2D(cellX + 1, cellY, x, y, w, h)
	local pp = self:extrapolate2D(cellX + 1, cellY + 1, x, y, w, h)
	
	return lerp(lerp(nn, pn, dx), lerp(np, pp, dx), dy)
end

function perlinerMethods:noise3D(x, y, z, w, h, d)
	local cellX, dx = modf(x)
	local cellY, dy = modf(y)
	local cellZ, dz = modf(z)
	
	dx = fade(dx)
	dy = fade(dy)
	dz = fade(dz)
	
	local nnn = self:extrapolate3D(cellX, cellY, cellZ, x,y,z, w,h,d)
	local npn = self:extrapolate3D(cellX, cellY+1, cellZ, x,y,z, w,h,d)
	local pnn = self:extrapolate3D(cellX+1, cellY, cellZ, x,y,z, w,h,d)
	local ppn = self:extrapolate3D(cellX+1, cellY+1, cellZ,  x,y,z, w,h,d)
	local nnp = self:extrapolate3D(cellX, cellY, cellZ+1, x,y,z, w,h,d)
	local npp = self:extrapolate3D(cellX, cellY+1, cellZ+1, x,y,z, w,h,d)
	local pnp = self:extrapolate3D(cellX+1, cellY, cellZ+1, x,y,z, w,h,d)
	local ppp = self:extrapolate3D(cellX+1, cellY+1, cellZ+1, x,y,z, w,h,d)
	
	return lerp(lerp(lerp(nnn, pnn, dx), lerp(npn, ppn, dx), dy), lerp(lerp(nnp, pnp, dx), lerp(npp, ppp, dx), dy), dz)
end

function perlinerMethods:extrapolate2D(cellX, cellY, x, y, w, h)
	local dx, dy = x - cellX, y - cellY
	
	if w then cellX = cellX % w end
	if h then cellY = cellY % h end
	
	local perm = self.perm
	local index = floor((perm[(perm[cellX % 256] + cellY) % 256]) / 2) % 8 * 2
	local g1, g2 = gradients2D[index], gradients2D[index+1]
	return g1*dx+g2*dy
end

function perlinerMethods:extrapolate3D(cellX, cellY, cellZ, x, y, z, w, h, d)
	local dx, dy, dz = x - cellX, y - cellY, z - cellZ
	
	if w then cellX = cellX % w end
	if h then cellY = cellY % h end
	if d then cellZ = cellZ % d end
	
	local perm = self.perm
	local index = self.permGradIndex3D[(perm[(perm[cellX % 256] + cellY) % 256] + cellZ) % 256]
	local g1, g2, g3 = gradients3D[index], gradients3D[index+1], gradients3D[index+2]
	return g1*dx+g2*dy+g3*dz
end


local simplexerMetatable = {__index = simplexerMethods}
local perlinerMetatable = {__index = perlinerMethods}
function noice.newNoiser(type, ...)
	local methodsMetatable = type == "OpenSimplex" and simplexerMetatable or type == "Perlin" and perlinerMetatable
	local new = setmetatable({}, methodsMetatable)
	new:init(...)
	return new
end

return noice
