local wave = require(script.gerstner)

local grid_size = vector.create(50, 0, 50)
local higher_offset = vector.zero
local lower_offset = vector.zero
local total_offset = vector.zero
local waves = {}

for i = 1, 20 do
	local w = wave.random { amplitude = 1 }
	higher_offset += vector.max(vector.zero, w.size)
	lower_offset += vector.min(vector.zero, w.size)

	table.insert(waves, w)
end

local function solve_plane(t: number)
	local sums = buffer.create(grid_size.x * grid_size.z * 4)
	total_offset = higher_offset - lower_offset
	for i, w in waves do
		wave.solve(w, t, grid_size, vector.create(0, 0, 0), sums, vector.abs(w.size) / total_offset)
	end

	coroutine.yield()
	local cursor = 0
	for i = 1, grid_size.x do
		for j = 1, grid_size.z do
			local xyz = buffer.readu32(sums, cursor)
			local x = bit32.extract(xyz, 0, 11)
			local y = bit32.extract(xyz, 11, 10)
			local z = bit32.extract(xyz, 21, 11)

			coroutine.yield(
				math.map(x, 0, 2 ^ 11, -lower_offset.x, higher_offset.x),
				math.map(y, 0, 2 ^ 10, -lower_offset.y, higher_offset.y),
				math.map(z, 0, 2 ^ 11, -lower_offset.z, higher_offset.z)
			)
			cursor += 4
		end
	end
	coroutine.yield()
end

return table.freeze {
	solve = function(t)
		local iter = coroutine.wrap(solve_plane)
		iter(t)
		return iter :: () -> (number, number, number)
	end,
}
