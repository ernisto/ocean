local function gcd(a: number, b: number): number
	while b ~= 0 do
		a, b = b, a % b
	end
	return a
end

local function integer_ratio(x: number, y: number): (number, number)
	if x == 0 and y == 0 then
		return 0, 0
	elseif x == 0 then
		return 0, 1
	elseif y == 0 then
		return 1, 0
	end

	local denom = 5
	local a = math.round(x * denom)
	local b = math.round(y * denom)

	local g = gcd(a, b)
	return a // g, b // g
end

return integer_ratio
