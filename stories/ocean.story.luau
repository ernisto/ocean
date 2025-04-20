local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local ocean = require(ReplicatedStorage.packages.ocean)
local story = require(ServerStorage.stories.story)

local function setup(target, props)
	local GRID_SIZE = props.grid_size
	local resolution = vector.create(GRID_SIZE, 0, GRID_SIZE)

	local m = ocean.mesh.create(resolution)
	local spectrum = ocean.wave.spectrum.new {
		ocean.wave.gerstner.random({ base_amplitude = 5, speed = 3 }),
		ocean.wave.gerstner.random({ base_amplitude = 5, speed = 3 }),
	}

	local vertices = m.vertices
	local part = m.part
	local mesh = m.mesh

	local set_vertex_pos = mesh.SetPosition
	local conn = game:GetService('RunService').RenderStepped:Connect(function()
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

return story.story({
	grid_size = 50,
}, setup)
