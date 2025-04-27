local material = require('./material')
local mesh = require('./mesh')
local wave = require('./wave')
local log = require('./log')

-- defs
export type params = {
	material: material.animated?,
	spectrum: wave.spectrum,
	resolution: vector,
	size: vector,
}
export type ocean = params & {
	mesh: mesh.ocean_mesh,
	part1: MeshPart,
	part2: MeshPart,
}

-- functions
local function setup(params: params): ocean
	log.ezsetup_on_client.assert()
	local size = params.size

	local ocean_mesh = mesh.create(params.resolution)
	ocean_mesh.part.Size = Vector3.new(size.x, size.y, size.z)

	local part1 = ocean_mesh.part
	part1.CFrame = CFrame.new(0, 20, 0)
	part1.Material = Enum.Material.Glass
	part1.Color = Color3.new(0.1, 0.4, 1)
	part1.Reflectance = 0
	part1.Transparency = 10
	part1.Parent = workspace
	part1.Size = Vector3.new(size.x, size.y, size.z)

	local highlight = Instance.new('Highlight', part1)
	highlight.OutlineTransparency = 1.00
	highlight.FillTransparency = 1.00

	local part2 = part1:Clone()
	part2.Material = Enum.Material.SmoothPlastic
	part2.Transparency = 0.50
	part2.Position += Vector3.new(0, 0.1, 0)
	part2.Parent = part1

	return table.freeze {
		resolution = params.resolution,
		material = params.material,
		spectrum = params.spectrum,
		mesh = ocean_mesh,
		size = size,

		part1 = part1,
		part2 = part2,
	}
end

-- methods
local function update_geometry(ocean: ocean)
	local camera_pos = workspace.CurrentCamera.CFrame.Position
	local ocean_pos = camera_pos * Vector3.new(1, 0, 1)

	local offsets = wave.spectrum.solve(
		ocean.spectrum,
		ocean.resolution,
		os.clock(),
		vector.create(camera_pos.X, camera_pos.Y, camera_pos.Z)
	)
	mesh.apply_vertex_offsets(ocean.mesh, offsets)

	ocean.part1.Position = ocean_pos
	ocean.part2.Position = ocean_pos + Vector3.new(0, 0.1, 0)
end
local function update_texture(ocean: ocean, material: material.animated)
	local variant_names = material.variant_names
	local name = variant_names[1 + os.clock() * material.fps % #variant_names // 1]
	ocean.part2.MaterialVariant = name
end

local function update(ocean: ocean)
	update_geometry(ocean)
	if ocean.material then update_texture(ocean, ocean.material) end
end

-- module
return table.freeze {
	update_geometry = update_geometry,
	update_texture = update_texture,
	update = update,
	setup = setup,
}
