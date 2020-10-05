local consts = {}

consts.maxTicksPerFrame = 3
consts.tickLength = 1/24 -- Length of a tick (fixed timestep stuff, y'know?)

consts.vertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal", "float", 3},
	{"VertexTangent", "float", 3},
	{"VertexBitangent", "float", 3}
}

return consts
