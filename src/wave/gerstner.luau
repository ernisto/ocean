--!optimize 2
--!native
--!nolint LocalShadow
local fast_sum_buffer = require('./fast_sum_buffer')
local integer_ratio = require('./integer_ratio')

-- defs
local GRAVITY = 9.81

export type wave = {
	direction: vector,
	offset: vector,
	ratio: vector,
	amplitude: number,
	steepness: number,
	length: number,
	speed: number,
	phase: number,
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
type unsigned_sin = number -- 0..2 instead of -1..1 - easier to transform into unsigned range
local function parabolic_sin(x: number): unsigned_sin
	x = (x % math.pi * 2) - math.pi
	return 1 + x * (4 / math.pi - 4 / (math.pi * math.pi) * math.abs(x))
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
		offset = vector.create(direction.x * steepness * amplitude, amplitude, direction.z * steepness * amplitude),
		ratio = vector.create(integer_ratio(math.abs(direction.x), math.abs(direction.z))),
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
	resolution: vector, -- recommended to be a power of 2 to avoid float operation artifacts
	out_sums: fast_sum_buffer.fast_sum_buffer?,
	_cell_scale: fast_sum_buffer.scaled_offset?
): buffer
	local result = out_sums or buffer.create(resolution.x * resolution.z * 4)
	local unsigned_sin_factor = (_cell_scale or vector.one) * fast_sum_buffer.range.max / 2
	local unsigned_sin_factor_x = unsigned_sin_factor.x
	local unsigned_sin_factor_y = unsigned_sin_factor.y
	local unsigned_sin_factor_z = unsigned_sin_factor.z

	local ratio = wave.ratio
	local a = time * wave.speed + wave.phase
	local interval = ratio.x * math.pi * 2 / (resolution.x + 1)

	local b = a % interval

	-- sin lookup
	local cap = 4 * resolution.x / ratio.x - 4
	local lookup = buffer.create(cap + ratio.x + 12)
	local offset = 0
	for angle = -math.pi + b, math.pi + b, interval do
		local sin_theta = parabolic_sin(angle)
		local cos_theta = parabolic_sin(angle + math.pi / 2)

		local cell = math.floor(cos_theta * unsigned_sin_factor_x)
			+ 2 ^ 11 * math.floor(sin_theta * unsigned_sin_factor_y)
			+ 2 ^ 21 * math.floor(cos_theta * unsigned_sin_factor_z)

		buffer.writeu32(lookup, offset, cell)
		offset += 4
	end

	-- print(ratio)
	local oo = 0 --math.map(a % (math.pi * 2), 0, math.pi * 2, 0, resolution.x) // 1 * 4
	for x = 0, resolution.x - 1 do
		-- buffer.copy(result, x * resolution.x * 4, lookup, offset, resolution.x * 4)
		for offset = 0, resolution.x * 4 - 4, 4 do
			local result_offset = x * resolution.x * 4 + offset
			local a = buffer.readu32(result, result_offset)
			local b = buffer.readu32(lookup, (oo + offset) % cap)
			buffer.writeu32(result, result_offset, a + b)
		end
		-- print(oo)
		-- oo = (oo + ratio.y * 4) % (resolution.x * 4)
	end
	return result
end

-- module
return table.freeze {
	random = random_wave,
	solve = solve_wave,
	new = wave,
}
