local AssetService = game:GetService('AssetService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local ocean = require(ReplicatedStorage.packages.ocean)
local story = require(ServerStorage.stories.story)

local function setup(target, props)
	local GRID_SIZE = props.grid_size
	local mesh = AssetService:CreateEditableMesh()

	-- Criar blocos
	local gridVerts = {}
	for y = 1, GRID_SIZE do
		gridVerts[y] = {}
		for x = 1, GRID_SIZE do
			gridVerts[y][x] = mesh:AddVertex(Vector3.new(x, 0, y))
		end
	end

	-- Conexão dos triângulos
	for y = 1, GRID_SIZE - 1 do
		for x = 1, GRID_SIZE - 1 do
			local v00 = gridVerts[y][x]
			local v10 = gridVerts[y][x + 1]
			local v01 = gridVerts[y + 1][x]
			local v11 = gridVerts[y + 1][x + 1]

			-- Cada célula forma dois triângulos
			mesh:AddTriangle(v00, v01, v10)
			mesh:AddTriangle(v01, v11, v10)
		end
	end

	-- Loop de simulação
	local conn = game:GetService('RunService').RenderStepped:Connect(function()
		local t = os.clock()
		local iter = ocean.solve(t)

		for y = 1, GRID_SIZE do
			for x = 1, GRID_SIZE do
				local vertexId = gridVerts[y][x]
				local px, py, pz = iter()
				mesh:SetPosition(vertexId, Vector3.new(x + px, py, y + pz))
			end
		end
	end)

	local content = Content.fromObject(mesh)
	local part = AssetService:CreateMeshPartAsync(content)
	part.Parent = workspace
	part.Color = Color3.new(0.1, 0.4, 1)
	part.Reflectance = 0.10
	part.Transparency = 0.30
	part.Size = Vector3.new(155, 0.005, 155)
	part.CFrame = CFrame.new(0, 20, 0)
	part.Material = Enum.Material.Glass

	return function()
		conn:Disconnect()
		part:Destroy()
	end
end

return story.story({ grid_size = 50 }, setup)
