local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local ocean = require(ReplicatedStorage.packages.ocean)
local story = require(ServerStorage.stories.story)

local function setup(target, props)
	local RESOLUTION = props.resolution
	if math.log(RESOLUTION, 2) % 1 ~= 0 then warn('solver is more stable with grid size of base 2 (2^n)') end

	local resolution = vector.create(RESOLUTION, 0, RESOLUTION)

	local m = ocean.mesh.create(resolution)
	local spectrum = ocean.wave.spectrum.new {
		ocean.wave.gerstner.new({ direction = vector.create(3, 0, 1), amplitude = 1 }),
		-- ocean.wave.gerstner.random({ amplitude = 5, speed = 3 }),
	}

	local vertices = m.vertices
	local mesh = m.mesh

	local part1 = m.part
	part1.Size = Vector3.new(155, 0.005, 155)
	part1.CFrame = CFrame.new(0, 20, 0)

	local part2 = part1:Clone()
	part2.Size = Vector3.new(155, 0.005, 155)
	part2.CFrame = CFrame.new(155, 20, 0)
	part2.Parent = workspace

	local set_vertex_pos = mesh.SetPosition
	local conn = game:GetService('RunService').RenderStepped:Connect(function()
		local time = os.clock()
		local offsets = ocean.wave.spectrum.solve(spectrum, resolution, time)

		local index = 1
		for z = 0, RESOLUTION - 1 do
			for x = 0, RESOLUTION - 1 do
				local vertex_id = vertices[index]
				local offset = offsets[index]

				set_vertex_pos(mesh, vertex_id, Vector3.new(x + offset.x, offset.y, z + offset.z))
				index += 1
			end
		end
	end)

	return function()
		conn:Disconnect()
		part1:Destroy()
		part2:Destroy()
	end
end

return story.story({
	resolution = 64,
}, setup)
