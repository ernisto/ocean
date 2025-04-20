--!optimize 2
--!native
local fast_sum_buffer = require('./fast_sum_buffer')

-- defs
local GRAVITY = 9.81

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

-- utils
local PI = math.pi
local TAU = PI * 2
local B = 4 / PI
local C = -4 / (PI * PI)

type unsigned_sin = number -- 0..2 instead of -1..1 - easier to transform into unsigned range
local function parabolic_sin(x: number): unsigned_sin
	x = (x % TAU) - PI
	return 1 + x * (B + C * math.abs(x))
end

-- functions
local function wave(params: wave_params): wave
	local direction = vector.normalize(params.direction or vector.create(1, 0, 1))
	local amplitude = params.amplitude or 1
	local length = params.length or 10

	local k = 2 * math.pi / length
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
		phase = params.phase or math.random() * 2 * math.pi,
	})
end

-- methods
local function solve_wave(
	wave: wave,
	time: number,
	grid_size: vector,
	grid_pos: vector,
	out_sums: fast_sum_buffer.fast_sum_buffer?,
	_cell_scale: fast_sum_buffer.scaled_offset?
): buffer
	local result = out_sums or buffer.create(grid_size.x * grid_size.z * 4)
	local unsigned_sin_factor = (_cell_scale or vector.one) * fast_sum_buffer.range.max / 2

	local kx = wave.k * wave.direction.x
	local kz = wave.k * wave.direction.z
	local a = time * wave.speed + wave.phase

	local offset = 0
	for z = grid_pos.z, (grid_pos.z + grid_size.z - 1) do
		for x = grid_pos.x, (grid_pos.x + grid_size.x - 1) do
			local theta = kz * z + kx * x - a

			local sin_theta = parabolic_sin(theta)
			local cos_theta = parabolic_sin(theta + math.pi / 2)

			local scaled_offset = vector.create(
				math.floor(cos_theta * unsigned_sin_factor.x),
				math.floor(sin_theta * unsigned_sin_factor.y),
				math.floor(cos_theta * unsigned_sin_factor.z)
			)
			fast_sum_buffer.add_cell(result, offset, scaled_offset)
			offset += 4
		end
	end
	return result
end

-- module
return table.freeze {
	random = random_wave,
	solve = solve_wave,
	new = wave,
}
