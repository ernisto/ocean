local fast_sum_buffer = require('../fast_sum_buffer')

local u32_bytes = 4
local cell_bytes = u32_bytes

local tau = math.pi * 2
local precision = 1000
local offset_from_radian = precision * u32_bytes

export type lookup = fast_sum_buffer.fast_sum_buffer

-- function
local function precompute(cell_scale: fast_sum_buffer.scaled_offset)
	local result = buffer.create(precision * cell_bytes)
	local offset = 0

	for theta = 0, tau - tau / precision, tau / precision do
		local double_unsigned_sin = vector.one + vector.create(math.cos(theta), math.sin(theta), math.cos(theta))
		local scaled_offset = cell_scale * double_unsigned_sin / 2

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
