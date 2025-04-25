local fast_sum_buffer = require('./fast_sum_buffer')
local lookup = require('./gerstner/lookup')
local wave = require('./gerstner')

-- defs
export type spectrum = {
	waves: { [wave.wave]: lookup.lookup },
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
	local total_offset = higher_offset - lower_offset
	local wave_lookups = {}

	for _, w in waves do
		local lookup_buffer = lookup.precompute(vector.abs(w.size) / total_offset)
		wave_lookups[w] = lookup_buffer
	end
	return table.freeze {
		waves = table.freeze(wave_lookups),
		higher_offset = higher_offset,
		lower_offset = lower_offset,
		total_offset = total_offset,
		period_size = period_size,
	}
end

-- methods
local function solve_point(spectrum: spectrum, point: vector, time: number)
	local n = vector.zero
	for w, lookup_buffer in spectrum.waves do
		n += wave.solve_point(w, time, point, lookup_buffer)
	end
	return n
end
local function solve(spectrum: spectrum, resolution: vector, time: number)
	local out_sums = buffer.create(resolution.x * resolution.z * 4)
	for w, lookup_buffer in spectrum.waves do
		wave.solve(w, time, resolution, vector.zero, lookup_buffer, out_sums)
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
	solve_point = solve_point,
	solve = solve,
	new = new,

	wave = wave,
}
