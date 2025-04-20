local fast_sum_buffer = require('./fast_sum_buffer')
local wave = require('./gerstner')

-- defs
export type spectrum = {
	waves: { wave.wave },
	higher_offset: vector,
	lower_offset: vector,
	total_offset: vector,
	period_size: vector,
}

-- constructor
local function new(waves: { wave.wave }): spectrum
	local higher_offset = vector.zero
	local lower_offset = vector.zero
	local period_size = vector.zero

	for _, w in waves do
		higher_offset += vector.max(vector.zero, w.size)
		lower_offset += vector.min(vector.zero, w.size)
	end
	return table.freeze {
		waves = table.freeze(table.clone(waves)),
		total_offset = higher_offset - lower_offset,
		higher_offset = higher_offset,
		lower_offset = lower_offset,
		period_size = period_size,
	}
end

-- methods
local function solve(spectrum: spectrum, resolution: vector, time: number)
	local out_sums = buffer.create(resolution.x * resolution.z * 4)
	for i, w in spectrum.waves do
		wave.solve(w, time, resolution, vector.zero, out_sums, vector.abs(w.size) / spectrum.total_offset)
	end

	local points = {}
	local index = 0

	for z = 1, resolution.z do
		for x = 1, resolution.x do
			local offset = fast_sum_buffer.read_scaled_offset(out_sums, index)
			local absolute_offset = offset * spectrum.total_offset - spectrum.lower_offset

			table.insert(points, absolute_offset)
			index += 4
		end
	end
	return points
end

-- module
return table.freeze {
	new = new,
	solve = solve,

	wave = wave,
}
