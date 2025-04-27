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
}

-- functions
local function setup(params: params): ocean
	log.ezsetup_on_client.assert()
	local size = params.size

	local ocean_mesh = mesh.create(params.resolution)
	ocean_mesh.part.Size = Vector3.new(size.x, size.y, size.z)

	local part = ocean_mesh.part
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(102, 125, 255)
	part.Transparency = 0.50
	part.Position += Vector3.new(0, 0.1, 0)
	part.Parent = workspace

	return table.freeze {
		resolution = params.resolution,
		material = params.material,
		spectrum = params.spectrum,
		mesh = ocean_mesh,
		size = size,
		part = part,
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

	ocean.mesh.part.Position = ocean_pos
end
local function update_texture(ocean: ocean, material: material.animated)
	local variant_names = material.variant_names
	local name = variant_names[1 + os.clock() * material.fps % #variant_names // 1]
	ocean.mesh.part.MaterialVariant = name
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
