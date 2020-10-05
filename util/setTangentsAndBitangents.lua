local function getTangentAndBitangent(x1,y1,z1, u1,v1, x2,y2,z2, u2,v2, x3,y3,z3, u3,v3)
	-- TEMP
	local p1 = vec3(x1, y1, z1)
	local p2 = vec3(x2, y2, z2)
	local p3 = vec3(x3, y3, z3)
	local t1 = vec2(u1, v1)
	local t2 = vec2(u2, v2)
	local t3 = vec2(u3, v3)
	
	local e1 = p2 - p1
	local e2 = p3 - p1
	local dt1 = t2 - t1
	local dt2 = t3 - t1
	
	local f = 1 / (dt1.x * dt2.y - dt1.y * dt2.x)
	local tangent = f * (dt2.y * e1 - dt1.y * e2)
	local bitangent = f * (-dt2.x * e1 + dt1.x * e2)
	
	return tangent.x, tangent.y, tangent.z, bitangent.x, bitangent.y, bitangent.z
end

return function(verts)
	for i = 0, #verts / 3 - 1 do
		local v1 = verts[i*3+1]
		local v2 = verts[i*3+2]
		local v3 = verts[i*3+3]
		local tx,ty,tz, bx,by,bz = getTangentAndBitangent(v1[1],v1[2],v1[3],v1[4],v1[5], v2[1],v2[2],v2[3],v2[4],v2[5], v3[1],v3[2],v3[3],v3[4],v3[5])
		v1[9],v1[10],v1[11],v1[12],v1[13],v1[14]=tx,ty,tz,bx,by,bz
		v2[9],v2[10],v2[11],v2[12],v2[13],v2[14]=tx,ty,tz,bx,by,bz
		v3[9],v3[10],v3[11],v3[12],v3[13],v3[14]=tx,ty,tz,bx,by,bz
	end
	return verts
end
