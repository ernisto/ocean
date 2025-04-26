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

	local part = m.part
	part.CFrame = CFrame.new(0, 20, 0)
	part.Material = Enum.Material.Glass
	part.Color = Color3.new(0.1, 0.4, 1)
	part.Reflectance = 0
	part.Transparency = 10
	part.Parent = workspace

	local highlight = Instance.new('Highlight', part)
	highlight.OutlineTransparency = 1.00
	highlight.FillTransparency = 1.00

	local part2 = part:Clone()
	part2.Material = Enum.Material.SmoothPlastic
	part2.Transparency = 0.50
	part2.MaterialVariant = water_material.Name
	part2.Position += Vector3.new(0, 0.1, 0)
	part2.Parent = part

	local conn = RunService.RenderStepped:Connect(function()
		local offsets = ocean.wave.spectrum.solve(spectrum, resolution, os.clock())
		ocean.mesh.apply_vertex_offsets(m, offsets)
	end)

	return function()
		conn:Disconnect()
		part:Destroy()
	end
end

return story.story({ grid_size = 64, wave_amount = 10 }, setup)
