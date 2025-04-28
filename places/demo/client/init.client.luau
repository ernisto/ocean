local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local ocean = require(ReplicatedStorage.packages.ocean)
local props = {
	wave_amount = 10,
	grid_size = 64,
}

local waves = {}
for i = 1, props.wave_amount do
	table.insert(waves, ocean.wave.gerstner.random({ base_amplitude = 5, steepness = 3 }))
end

local setup = ocean.ezsetup.setup({
	resolution = vector.create(props.grid_size, 0, props.grid_size),
	size = vector.create(255, 0, 255),
	spectrum = ocean.wave.spectrum.new(waves),
	material = ocean.material.roblox.new(1 / 2),
})

RunService:BindToRenderStep('ocean', Enum.RenderPriority.Last.Value, function(delta_time)
	ocean.ezsetup.update(setup)
end)
