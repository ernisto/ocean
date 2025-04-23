-- we cant waste space storing absolute displacement or world position
-- because the precision of the float is not enough
export type scaled_offset = vector -- offset / spectrum.total_offset
type scale = number -- 0..1

-- packing them into a single 32-bit integer consumes less memory
-- and allows us to fastly add them with another waves
export type fast_sum_buffer = buffer -- packed_cell[w*h]
type packed_cell = u32 -- (u11, u10, u11)
type cell = vector -- (u11, u10, u11)
type offset = number -- 0..:4

type u32 = number
local u32_bytes = 32 / 8

type u11 = number -- 0..2047
local u11 = 2 ^ 11 - 1

type u10 = number -- 0..1023
local u10 = 2 ^ 10 - 1

export type normalized_offset = vector -- (u11, u10, u11)
local min = vector.zero
local max = vector.create(u11, u10, u11)

-- functions
local function offset(index: number): offset
	return index * u32_bytes
end

local function unpack_cell(packed_cell: packed_cell): scaled_offset
	return vector.create(
		bit32.extract(packed_cell, 0, 11),
		bit32.extract(packed_cell, 11, 10),
		bit32.extract(packed_cell, 11 + 10, 11)
	)
end
local function pack_cell(cell: vector): packed_cell
	return math.floor(cell.x) + bit32.lshift(math.floor(cell.y), 11) + bit32.lshift(math.floor(cell.z), 11 + 10)
end

local function scale_cell(packed_cell: packed_cell): scaled_offset
	return unpack_cell(packed_cell) / max
end
local function pack_scaled_offset(scaled_offset: scaled_offset): packed_cell
	return pack_cell(scaled_offset * max)
end

local function read_scaled_offset(buff: fast_sum_buffer, offset: offset): scaled_offset
	return scale_cell(buffer.readu32(buff, offset))
end
local function write_scaled_offset(buff: fast_sum_buffer, offset: offset, scaled_offset: scaled_offset)
	buffer.writeu32(buff, offset, pack_scaled_offset(scaled_offset))
end

-- heres why we are using buffer instead of {vector}
local function add_scaled_offset(buff: fast_sum_buffer, offset: offset, scaled_offset: scaled_offset)
	buffer.writeu32(buff, offset, buffer.readu32(buff, offset) + pack_scaled_offset(scaled_offset))
end
local function add_cell(buff: fast_sum_buffer, offset: offset, cell: cell)
	buffer.writeu32(buff, offset, buffer.readu32(buff, offset) + pack_cell(cell))
end

-- module
return table.freeze {
	range = table.freeze { min = min, max = max },
	offset = offset,

	unpack_cell = unpack_cell,
	pack_cell = pack_cell,

	pack_scaled_offset = pack_scaled_offset,
	scale_cell = scale_cell,

	write_scaled_offset = write_scaled_offset,
	read_scaled_offset = read_scaled_offset,

	add_scaled_offset = add_scaled_offset,
	add_cell = add_cell,
}
