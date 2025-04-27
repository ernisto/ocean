local spectrum = require(script.spectrum)
export type spectrum = spectrum.spectrum

local gerstner = require(script.gerstner)
export type gerstner = gerstner.wave

-- module
return table.freeze {
	gerstner = gerstner,
	spectrum = spectrum,
}
