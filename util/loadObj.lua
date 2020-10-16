local setTangentsAndBitangents = require("util.gfx.setTangentsAndBitangents")

return function(path)
	local geometry = {}
	local uv = {}
	local normal, bitangent, tangent = {}, {}, {}
	local outVerts = {}
	
	for line in love.filesystem.lines(path) do
		local item
		local isTri = false
		for word in line:gmatch("%S+") do
			if item then
				if isTri then
					local iterator = word:gmatch("%d+")
					local v = geometry[tonumber(iterator())]
					local vt = uv[tonumber(iterator())]
					local vn = normal[tonumber(iterator())]
					
					local vert = { -- see constants.vertexFormat
						v[1], v[2], v[3],
						vt[1], 1 - vt[2], -- Love --> OpenGL
						vn[1], vn[2], vn[3]
					}
					outVerts[#outVerts+1] = vert
				else
					item[#item+1] = tonumber(word)
				end
			elseif word == "#" then
				break
			elseif word == "s" then
				-- TODO
				break
			elseif word == "v" then
				item = {}
				geometry[#geometry+1] = item
			elseif word == "vt" then
				item = {}
				uv[#uv+1] = item
			elseif word == "vn" then
				item = {}
				normal[#normal+1] = item
			elseif word == "f" then
				item = {}
				isTri = true
			else
				-- error("idk what \"" .. word .. "\" in \"" .. line .. "\" is, sorry")
			end
		end
	end
	setTangentsAndBitangents(outVerts)
	return love.graphics.newMesh(consts.vertexFormat, outVerts, "triangles"), outVerts
end
