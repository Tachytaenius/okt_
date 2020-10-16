-- NOTE: NOT PARTICULARLY COMPREHENSIVE. ONLY REALLY ADDED THINGS WHEN NEEDED.

local detmath = require("lib.detmath")

local ffi = require("ffi")
ffi.cdef([=[
	typedef struct {
		float x, y, z, w;
	} quat;
]=])

local ffi_istype = ffi.istype

local new_ = ffi.typeof("quat")
local function new(x, y, z, w)
	if x then
		if w then
			return new_(x, y, z, w)
		else
			return new(x, y, z, 0)
		end
	else
		return new_(0, 0, 0, 1)
	end
end

local sqrt, sin, cos, acos, detsin, detcos, detacos = math.sqrt, math.sin, math.cos, math.acos, detmath.sin, detmath.cos, detmath.acos

local function length(q)
	local x, y, z, w = q.x, q.y, q.z, q.w
	return sqrt(x * x + y * y + z * z + w * w)
end

local function normalize(q)
	local len = #q
	return new(q.x / len, q.y / len, q.z / len, q.w / len)
end

local function inverse(q)
	return new(-q.x, -q.y, -q.z, q.w)
end

local function dot(a, b)
	return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
end

local function slerp(a, b, i)
	if a == b then return a end
	
	local cosHalfTheta = dot(a, b)
	local halfTheta = acos(cosHalfTheta)
	local sinHalfTheta = sqrt(1 - cosHalfTheta^2)
	
	return a * (sin((1 - i) * halfTheta) / sinHalfTheta) + b * (sin(i * halfTheta) / sinHalfTheta)
end

local function detSlerp(a, b, i)
	if a == b then return a end
	
	local cosHalfTheta = dot(a, b)
	local halfTheta = acos(cosHalfTheta)
	local sinHalfTheta = sqrt(1 - cosHalfTheta*cosHalfTheta)
	
	return a * (detsin((1 - i) * halfTheta) / sinHalfTheta) + b * (detsin(i * halfTheta) / sinHalfTheta)
end

local function fromAxisAngle(v)
	local angle = #v
	if angle == 0 then return new() end
	local axis = v / angle
	local s, c = sin(angle / 2), cos(angle / 2)
	return normalize(new(axis.x * s, axis.y * s, axis.z * s, c))
end

local function detFromAxisAngle(v)
	local angle = #v
	if angle == 0 then return new() end
	local axis = v / angle
	local s, c = detsin(angle / 2), detcos(angle / 2)
	return normalize(new(axis.x * s, axis.y * s, axis.z * s, c))
end

local function components(q)
	return q.x, q.y, q.z, q.w
end

local quat = setmetatable({
	new = new,
	length = length,
	normalize = normalize,
	inverse = inverse,
	dot = dot,
	slerp = slerp,
	detSlerp = detSlerp,
	fromAxisAngle = fromAxisAngle,
	detFromAxisAngle = detFromAxisAngle,
	components = components
}, {
	__call = function(_, x, y, z, w)
		return new(x, y, z, w)
	end
})

ffi.metatype("quat", {
	__unm = function(a)
		return new(-a.x, -a.y, -a.z, -a.w)
	end,
	__mul = function(a, b)
		local isQuat = type(b) == "cdata" and ffi_istype("quat", b)
		if isQuat then
			return new(
				a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y,
				a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z,
				a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x,
				a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
			)
		else
			return new(a.x * b, a.y * b, a.z * b, a.w * b)
		end
	end,
	__add = function(a, b)
		return new(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
	end,
	__eq = function(a, b)
		local isQuat = type(b) == "cdata" and ffi_istype("quat", b)
		return isQuat and a.x == b.x and a.y == b.y and a.z == b.z and a.w == b.w
	end,
	__len = length,
	__tostring = function(a)
		return string.format("quat(%f, %f, %f, %f)", a.x, a.y, a.z, a.w)
	end
})

return quat
