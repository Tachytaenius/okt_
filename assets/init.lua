-- All TEMP/TODO

local loadObj = require("util.loadObj")
local getMergedMaps = require("util.gfx.getMergedMaps")
local function newAsset(path)
	local albedoEmissionMap, normalAmbientOcclusionMap, roughnessMetalnessDielectricF0Map = getMergedMaps(path)
	return {
		mesh = loadObj("assets/" .. path .. "/mesh.obj"),
		albedoEmissionMap = albedoEmissionMap, normalAmbientOcclusionMap = normalAmbientOcclusionMap, roughnessMetalnessDielectricF0Map = roughnessMetalnessDielectricF0Map
	}
end

local assets = {}
function assets.getAsset(model)
	return assets[model.asset]
end
assets.boi = newAsset("entity/boi")
assets.ball = newAsset("entity/ball")
assets.floar = newAsset("entity/floar")
assets.bullet = newAsset("entity/bullet")
return assets
