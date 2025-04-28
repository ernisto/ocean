--!optimize 2
local fast_sum_buffer = require(script.Parent.fast_sum_buffer) -- require('../fast_sum_buffer')
local lookup = require(script.lookup) -- require('./lookup')
local lookup_cell_bytes = lookup.cell_bytes
local lookup_precision = lookup.precision

-- defs
local GRAVITY = 9.81
local tau = 2 * math.pi

export type wave = {
	direction: vector,
	amplitude: number,
	steepness: number,
	length: number,
	speed: number,
	phase: number,
	size: vector,
	k: number,
}
type wave_params = {
	direction: vector?,
	amplitude: number?,
	steepness: number?,
	length: number?,
	phase: number?,
}

-- functions
local function wave(params: wave_params): wave
	local direction = vector.normalize(params.direction or vector.create(1, 0, 1))
	local amplitude = params.amplitude or 1
	local length = params.length or 10

	local k = tau / length
	local speed = math.sqrt(GRAVITY * k) -- gravity-based dispersion
	local steepness = params.steepness or k

	return table.freeze {
		size = vector.create(direction.x * steepness * amplitude, amplitude, direction.z * steepness * amplitude),
		amplitude = amplitude,
		steepness = steepness,
		direction = direction,
		length = length,
		phase = params.phase or 0,
		speed = speed,
		k = k,
	}
end
local function random_wave(params: wave_params & { base_amplitude: number? }): wave
	return wave({
		direction = params.direction or vector.normalize(vector.create(math.random() - 0.5, 0, math.random() - 0.5)),
		amplitude = params.amplitude or (params.base_amplitude or 1) * math.random() * 0.2,
		length = params.length or math.random() * 20 + 5,
		phase = params.phase or math.random() * tau,
	})
end

-- methods
@native
local function solve_wave_point(wave: wave, time: number, grid_pos: vector, lookup_buffer: lookup.lookup): vector
	local a = time * wave.speed + wave.phase
	local theta = wave.k * vector.dot(wave.direction, grid_pos) - a

	local lookup_offset = math.floor(theta / tau * lookup_precision)
		* lookup_cell_bytes
		% (lookup_cell_bytes * lookup_precision)

	local scaled_offset = buffer.readu32(lookup_buffer, lookup_offset)
	return fast_sum_buffer.scale_cell(scaled_offset)
end

@native
local function solve_wave(
	wave: wave,
	time: number,
	grid_size: vector,
	grid_pos: vector,
	lookup_buffer: lookup.lookup,
	out_sums: fast_sum_buffer.fast_sum_buffer?
): buffer
	local result = out_sums or buffer.create(grid_size.x * grid_size.z * 4)
	local offset = 0

	local kx = wave.k * wave.direction.x
	local kz = wave.k * wave.direction.z
	local a = time * wave.speed + wave.phase

	for z = grid_pos.z, (grid_pos.z + grid_size.z - 1) do
		for x = grid_pos.x, (grid_pos.x + grid_size.x - 1) do
			local theta = (kz * z + kx * x - a)
			local lookup_offset = math.floor(theta / tau * lookup_precision)
				* lookup_cell_bytes
				% (lookup_cell_bytes * lookup_precision)

			local scaled_offset = buffer.readu32(lookup_buffer, lookup_offset)
			buffer.writeu32(result, offset, buffer.readu32(result, offset) + scaled_offset)
			offset += 4
		end
	end
	return result
end

-- module
return table.freeze {
	random = random_wave,
	solve_point = solve_wave_point,
	solve = solve_wave,
	new = wave,
}
