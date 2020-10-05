-- NOTE: NOT PARTICULARLY COMPREHENSIVE. ONLY REALLY ADDED THINGS WHEN NEEDED.

local detmath = require("lib.detmath")

local ffi = require("ffi")
ffi.cdef([=[
	typedef struct {
		float x, y;
	} vec2;
]=])

local ffi_istype = ffi.istype

local new_ = ffi.typeof("vec2")
local function new(x, y)
	x = x or 0
	y = y or x
	return new_(x, y)
end

local sqrt, sin, cos = math.sqrt, math.sin, math.cos
local detsin, detcos = detmath.sin, detmath.cos

local function length(a)
	local x, y = a.x, a.y
	return sqrt(x * x + y * y)
end

local function length2(a)
	local x, y = a.x, a.y
	return x * x + y * y
end

local function distance(a, b)
	local x, y = b.x - a.x, b.y - a.y
	return sqrt(x * x + y * y)
end

local function distance2(a, b)
	local x, y = b.x - a.x, b.y - a.y
	return x * x + y * y
end

local function dot(a, b)
	return a.x * b.x + a.y * b.y
end

local function normalize(a)
	return a/length(a)
end

local function reflect(incident, normal)
	return incident - 2 * dot(normal, incident) * normal
end

local function refract(incident, normal, eta)
	local ndi = dot(normal, incident)
	local k = 1 - eta * eta * (1 - ndi * ndi)
	if k < 0 then
		return new(0, 0)
	else
		return eta * incident - (eta * ndi + sqrt(k)) * normal
	end
end

local function rotate(v, a)
	local x, y = v.x, v.y
	return vec2(
		x * cos(a) - y * sin(a),
		y * cos(a) + x * sin(a)
	)
end

local function detrotate(v, a)
	local x, y = v.x, v.y
	return vec2(
		x * detcos(a) - y * detsin(a),
		y * detcos(a) + x * detsin(a)
	)
end

local vec2 = setmetatable({
	new = new,
	length = length,
	length2 = length2,
	distance = distance,
	distance2 = distance2,
	dot = dot,
	normalize = normalize,
	reflect = reflect,
	refract = refract,
	rotate = rotate,
	detrotate = detrotate
}, {
	__call = function(_, x, y)
		return new(x, y)
	end
})

ffi.metatype("vec2", {
	__add = function(a, b)
		if type(a) == "number" then
			return new(a + b.x, a + b.y)
		elseif type(b) == "number" then
			return new(a.x + b, a.y + b)
		else
			return new(a.x + b.x, a.y + b.y)
		end
	end,
	__sub = function(a, b)
		if type(a) == "number" then
			return new(a - b.x, a - b.y)
		elseif type(b) == "number" then
			return new(a.x - b, a.y - b)
		else
			return new(a.x - b.x, a.y - b.y)
		end
	end,
	__unm = function(a)
		return new(-a.x, -a.y)
	end,
	__mul = function(a, b)
		if type(a) == "number" then
			return new(a * b.x, a * b.y)
		elseif type(b) == "number" then
			return new(a.x * b, a.y * b)
		else
			return new(a.x * b.x, a.y * b.y)
		end
	end,
	__div = function(a, b)
		if type(a) == "number" then
			return new(a / b.x, a / b.y)
		elseif type(b) == "number" then
			return new(a.x / b, a.y / b)
		else
			return new(a.x / b.x, a.y / b.y)
		end
	end,
	__mod = function(a, b)
		if type(a) == "number" then
			return new(a % b.x, a % b.y)
		elseif type(b) == "number" then
			return new(a.x % b, a.y % b)
		else
			return new(a.x % b.x, a.y % b.y)
		end
	end,
	__eq = function(a, b)
		local isVec2 = type(b) == "cdata" and ffi_istype("vec2", b)
		return isVec2 and a.x == b.x and a.y == b.y
	end,
	__len = length,
	__tostring = function(a)
		return string.format("vec2(%f, %f)", a.x, a.y)
	end
})

return vec2
