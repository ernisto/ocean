--!optimize 2
--!native

-- defs
local GRAVITY = 9.81

export type wave = {
	direction: vector,
	amplitude: number,
	steepness: number,
	length: number,
	omega: number,
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

local function parabolic_sin(x: number)
	x = (x % TAU) - math.pi
	return B * x + C * x * math.abs(x)
end

-- functions
local function wave(params: wave_params): wave
	local direction = vector.normalize(params.direction or vector.create(1, 0, 1))
	local amplitude = params.amplitude or 1
	local length = params.length or 10

	local k = 2 * math.pi / length
	local omega = math.sqrt(GRAVITY * k) -- gravity-based dispersion
	local steepness = params.steepness or k

	return table.freeze {
		size = vector.create(direction.x * steepness * amplitude, amplitude, direction.z * steepness * amplitude),
		amplitude = amplitude,
		steepness = steepness,
		direction = direction,
		length = length,
		phase = params.phase or 0,
		omega = omega,
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
	out_sums: buffer?,
	_cell_size: vector?
): buffer
	debug.profilebegin('gerstner wave solve')
	-- each cell consumes 3 bytes, but we write 4 bytes
	-- so we need allocate the extra byte just to the last cell dont access out of bounds
	local result = out_sums or buffer.create(grid_size.x * grid_size.z * 4)
	local cell_size = _cell_size or vector.one
	local x_factor = cell_size.x * 2 ^ 11 / 2
	local y_factor = cell_size.y * 2 ^ 10 / 2
	local z_factor = cell_size.z * 2 ^ 11 / 2

	local kx = wave.k * wave.direction.x
	local kz = wave.k * wave.direction.z
	local a = time * wave.omega + wave.phase

	local offset = 0
	for z = grid_pos.z, (grid_pos.z + grid_size.z - 1) do
		for x = grid_pos.x, (grid_pos.x + grid_size.x - 1) do
			local theta = kz * z + kx * x - a

			type unsigned_sin = number -- 0..2 instead of -1..1 - easier to transform into unsigned range
			local sin_theta: unsigned_sin = parabolic_sin(theta) + 1
			local cos_theta: unsigned_sin = parabolic_sin(theta + math.pi / 2) + 1

			-- packing them into a single 32-bit integer consumes less memory
			-- and allows us to fastly add them with another waves
			local cell_pack = math.floor(cos_theta * x_factor)
				+ 2 ^ 11 * math.floor(sin_theta * y_factor)
				+ 2 ^ 21 * math.floor(cos_theta * z_factor)

			buffer.writeu32(result, offset, buffer.readu32(result, offset) + cell_pack)
			offset += 4
		end
	end
	debug.profileend()
	return result
end

-- module
return table.freeze {
	random = random_wave,
	solve = solve_wave,
	new = wave,
}
