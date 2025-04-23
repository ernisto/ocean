local fast_sum_buffer = require('../fast_sum_buffer')

local u32_bytes = 4
local cell_bytes = u32_bytes

local tau = math.pi * 2
local precision = 1000
local offset_from_radian = precision * u32_bytes

export type lookup = fast_sum_buffer.fast_sum_buffer

-- function
local function precompute(cell_scale: fast_sum_buffer.scaled_offset)
	local unsigned_sin_factor = cell_scale / 2

	local result = buffer.create(precision * cell_bytes)
	local offset = 0

	for theta = 0, tau - tau / precision, tau / precision do
		local scaled_offset = vector.create(
			(math.cos(theta) + 1) * unsigned_sin_factor.x,
			(math.sin(theta) + 1) * unsigned_sin_factor.y,
			(math.cos(theta) + 1) * unsigned_sin_factor.z
		)
		fast_sum_buffer.write_scaled_offset(result, offset, scaled_offset)
		offset += cell_bytes
	end
	return result
end

-- module
return table.freeze {
	precompute = precompute,
	offset_from_radian = offset_from_radian,
	precision = precision,
	cell_bytes = cell_bytes,
}
