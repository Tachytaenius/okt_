-- All TEMP/TODO

local loadObj = require("assets.loadObj")
local getMergedMaps = require("assets.getMergedMaps")
local function newAsset(path)
	local albedoEmissionMap, normalAmbientOcclusionMap, roughnessMetalnessDielectricF0Map = getMergedMaps(path)
	return {
		mesh = loadObj("assets/" .. path .. "/mesh.obj"),
		albedoEmissionMap = albedoEmissionMap, normalAmbientOcclusionMap = normalAmbientOcclusionMap, roughnessMetalnessDielectricF0Map = roughnessMetalnessDielectricF0Map
	}
end

local assets = {}
function assets.getAsset(drawable)
	return assets[drawable.asset]
end
assets.boi = newAsset("boi")
assets.ball = newAsset("ball")
return assets
