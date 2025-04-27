local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')

local ocean = require(ReplicatedStorage.packages.ocean)
local story = require(ServerStorage.stories.story)

local function setup(target, props)
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

	RunService:BindToRenderStep('ocean', Enum.RenderPriority.Camera.Value + 1, function(delta_time)
		ocean.ezsetup.update(setup)
	end)

	return function()
		RunService:UnbindFromRenderStep('ocean')
		setup.mesh.part:Destroy()
	end
end

return story.story({ grid_size = 64, wave_amount = 10 }, setup)
