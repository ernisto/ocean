local AssetService = game:GetService('AssetService')

-- defs
export type vertex_id = number
export type face = { id: number, v1: vertex_id, v2: vertex_id, v3: vertex_id }
export type ocean_mesh = {
	mesh: EditableMesh,
	part: MeshPart,
	vertices: { vertex_id },
	faces: { face },
}

-- functions
local function create(size: vector): ocean_mesh
	local mesh = AssetService:CreateEditableMesh()
	local vertices = {}
	local faces = {}

	for z = 0, size.z - 1 do
		for x = 0, size.x - 1 do
			table.insert(vertices, mesh:AddVertex(Vector3.new(x, 0, z)))
		end
	end

	for z = 0, size.z - 2 do
		for x = 1, size.x - 1 do
			local v00 = vertices[(x + 0) + size.x * (z + 0)]
			local v10 = vertices[(x + 1) + size.x * (z + 0)]
			local v01 = vertices[(x + 0) + size.x * (z + 1)]
			local v11 = vertices[(x + 1) + size.x * (z + 1)]

			local f1 = mesh:AddTriangle(v00, v01, v10)
			local f2 = mesh:AddTriangle(v01, v11, v10)

			table.insert(faces, { id = f1, v1 = v00, v2 = v01, v3 = v10 })
			table.insert(faces, { id = f2, v1 = v01, v2 = v11, v3 = v10 })
		end
	end

	local content = Content.fromObject(mesh)
	local part = AssetService:CreateMeshPartAsync(content)
	part.Size = Vector3.new(155, 0.005, 155)
	part.CFrame = CFrame.new(0, 20, 0)
	part.Parent = workspace

	return table.freeze {
		part = part,
		mesh = mesh,
		faces = faces,
		vertices = vertices,
	}
end

-- module
return table.freeze {
	create = create,
}
