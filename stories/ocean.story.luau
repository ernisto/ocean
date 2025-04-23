local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

local ocean = require(ReplicatedStorage.packages.ocean)
local story = require(ServerStorage.stories.story)

local function setup(target, props)
	local GRID_SIZE = props.grid_size
	local resolution = vector.create(GRID_SIZE, 0, GRID_SIZE)

	local water_material = require(script.Parent.mock_water_material)

	local waves = {}
	for i = 1, props.wave_amount do
		table.insert(waves, ocean.wave.gerstner.random({ base_amplitude = 5, steepness = 3 }))
	end

	local m = ocean.mesh.create(resolution)
	local spectrum = ocean.wave.spectrum.new(waves)

	local vertices = m.vertices
	local mesh = m.mesh

	local part = m.part
	part.Material = Enum.Material.Glass
	part.Color = Color3.new(0.1, 0.4, 1)
	part.Reflectance = 0
	part.Transparency = 10

	local highlight = Instance.new('Highlight', part)
	highlight.OutlineTransparency = 1.00
	highlight.FillTransparency = 1.00

	local part2 = part:Clone()
	part2.Material = Enum.Material.SmoothPlastic
	part2.Transparency = 0.50
	part2.MaterialVariant = water_material.Name
	part2.Position += Vector3.new(0, 0.1, 0)
	part2.Parent = part

	local set_vertex_pos = mesh.SetPosition
	local conn = RunService.RenderStepped:Connect(function()
		local time = os.clock()
		local offsets = ocean.wave.spectrum.solve(spectrum, resolution, time)

		local index = 1
		for z = 0, GRID_SIZE - 1 do
			for x = 0, GRID_SIZE - 1 do
				local vertex_id = vertices[index]
				local offset = offsets[index]

				set_vertex_pos(mesh, vertex_id, Vector3.new(x + offset.x, offset.y, z + offset.z))
				index += 1
			end
		end
	end)

	return function()
		conn:Disconnect()
		part:Destroy()
	end
end

return story.story({ grid_size = 64, wave_amount = 10 }, setup)
