local MaterialService = game:GetService('MaterialService')
local RunService = game:GetService('RunService')
local StudioService = game:GetService('StudioService')

local mat: MaterialVariant = MaterialService:FindFirstChild('Water') :: any
if mat then return mat end

-- init
local files: { File } = StudioService:PromptImportFiles({ 'png' }) :: any
table.sort(files, function(a, b)
	return a.Name < b.Name
end)

mat = Instance.new('MaterialVariant', MaterialService)
assert(mat)
mat.MaterialPattern = Enum.MaterialPattern.Organic
mat.BaseMaterial = Enum.Material.SmoothPlastic
mat.StudsPerTile = 50
mat.Name = 'Water'

local ids = {}
for index, file in files do
	table.insert(ids, file:GetTemporaryId())
end

local conn
conn = RunService.Heartbeat:Connect(function()
	if not mat.Parent then return conn:Disconnect() end
	mat.NormalMap = ids[1 + os.clock() * 40 % #ids // 1]
end)

return mat
