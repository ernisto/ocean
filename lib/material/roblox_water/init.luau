local MaterialService = game:GetService('MaterialService')

local function new(cycle_duration: number)
	local variant_names = {}
	local variants = script.variants:Clone()

	for i = 1, #variants:Clone():GetChildren() do
		local variant = variants:FindFirstChild(`water_{i}`)
		if not variant then continue end

		table.insert(variant_names, variant.Name)
		variant.Parent = MaterialService
	end

	return table.freeze {
		variant_names = variant_names,
		fps = #variant_names / cycle_duration,
	}
end

return table.freeze { new = new }
