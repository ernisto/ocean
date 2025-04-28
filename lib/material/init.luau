-- defs
export type material = static | animated
export type static = {} -- idk if static material is useful, atm unused
export type animated = {
	variant_names: { string },
	fps: number,
}

-- module
return table.freeze {
	roblox = require(script.roblox_water),
}
