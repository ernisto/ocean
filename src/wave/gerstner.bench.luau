local wave = require('./gerstner')

local grid_size = vector.create(100, 0, 100)
local w = wave.random {}

local b = os.clock()
wave.solve(w, os.clock(), grid_size, vector.create(0, 0, 0))
local e = os.clock()

print(e - b)
return nil
