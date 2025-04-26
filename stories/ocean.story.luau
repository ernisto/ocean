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

	local emitters = {}
	local attachments = {}
	for x = 0, GRID_SIZE do
		for z = 0, GRID_SIZE do
			local attachment = Instance.new('Attachment', part)
			table.insert(attachments, attachment)

			local foam_emitter = Instance.new('ParticleEmitter', attachment)
			foam_emitter.Color = ColorSequence.new(Color3.new(1, 1, 1))
			foam_emitter.Transparency = NumberSequence.new {
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}
			foam_emitter.Lifetime = NumberRange.new(0.1, 0.5)
			-- foam_emitter.Rate = 50
			foam_emitter.Speed = NumberRange.new(2, 2.5)
			foam_emitter.Size = NumberSequence.new(2)
			foam_emitter.Enabled = false
			foam_emitter.Texture = 'rbxasset://textures/particles/smoke_main.dds'
			foam_emitter.SpreadAngle = Vector2.new(180, 180)
			foam_emitter.LockedToPart = true
			table.insert(emitters, foam_emitter)
		end
	end

	local function get_slope(offsets: { vector }, x, z): number
		if x <= 0 or x >= GRID_SIZE - 1 or z <= 0 or z >= GRID_SIZE - 1 then return 0 end

		local yL = offsets[z * GRID_SIZE + (x - 1) + 1].y
		local yR = offsets[z * GRID_SIZE + (x + 1) + 1].y
		local yD = offsets[(z - 1) * GRID_SIZE + x + 1].y
		local yU = offsets[(z + 1) * GRID_SIZE + x + 1].y

		local dx = (yR - yL) * 0.5
		local dz = (yU - yD) * 0.5

		local slope = math.sqrt(dx * dx + dz * dz)
		return slope
	end

	local last_offsets = table.create((GRID_SIZE + 1) ^ 2, vector.zero)
	local last_slopes = table.create((GRID_SIZE + 1) ^ 2, 0)

	local set_vertex_pos = mesh.SetPosition
	local conn = RunService.RenderStepped:Connect(function(delta_time)
		local time = os.clock()
		local offsets = ocean.wave.spectrum.solve(spectrum, resolution, time)

		local scale = part.Size / part.MeshSize

		local index = 1
		for z = 0, GRID_SIZE - 1 do
			for x = 0, GRID_SIZE - 1 do
				local attachment = attachments[index]
				local foam_emitter = emitters[index]
				local vertex_id = vertices[index]
				local offset = offsets[index]

				local p = vector.create(x - 0.5, 0, z - 0.5) - vector.create(GRID_SIZE, 0, GRID_SIZE) / 2 + offset
				set_vertex_pos(mesh, vertex_id, Vector3.new(p.x, p.y, p.z))
				index += 1

				local slope = get_slope(offsets, x, z)
				local last_slope = last_slopes[index]
				local last_offset = last_offsets[index]
				last_offsets[index] = offset
				last_slopes[index] = slope

				if offset.y - last_offset.y < 0.9 * delta_time then continue end
				if slope - last_slope < 0.6 * delta_time then continue end

				local world_pos = p + vector.create(1, 2.5, 1)
				attachment.CFrame = CFrame.new(world_pos.x * scale.X, world_pos.y * scale.Y, world_pos.z * scale.Z)
				foam_emitter:Emit(1)
			end
		end
	end)

	return function()
		conn:Disconnect()
		part:Destroy()
	end
end

return story.story({ grid_size = 64, wave_amount = 10 }, setup)
