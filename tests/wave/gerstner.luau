local gerstner = require('../../lib/wave/gerstner')
local lookup = require('../../lib/wave/gerstner/lookup')

local grid_size = vector.create(100, 0, 100)
local w = gerstner.random {}

local lookup_buffer = lookup.precompute(vector.one)

local b = os.clock()
gerstner.solve(w, os.clock(), grid_size, vector.zero, lookup_buffer)
local e = os.clock()

print(e - b)
return nil
