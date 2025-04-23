local lookup = require('./lookup')
local wave = require('..')

local grid_size = vector.create(100, 0, 100)
local w = wave.random {}

local lookup_buffer = lookup.precompute(vector.one)

local b = os.clock()
wave.solve(w, os.clock(), grid_size, vector.create(0, 0, 0), lookup_buffer)
local e = os.clock()

print(e - b)
return nil
