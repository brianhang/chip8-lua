local settings = {}

-- Side length for one pixel.
settings.PIXEL_SIZE = 8

-- Which ROM to use.
settings.ROM = "INVADERS2"

-- How many instructions are executed in 1 cycle.
settings.INSTR_PER_CYCLE = 10

-- The key mappings for the CHIP-8 keyboard.
settings.KEY_MAPPING = {
	["1"] = 0x1,
	["2"] = 0x2,
	["3"] = 0x3,
	["4"] = 0xC,
	["q"] = 0x4,
	["w"] = 0x5,
	["e"] = 0x6,
	["r"] = 0xD,
	["a"] = 0x7,
	["s"] = 0x8,
	["d"] = 0x9,
	["f"] = 0xE,
	["z"] = 0xA,
	["x"] = 0x0,
	["c"] = 0xB,
	["v"] = 0xF
}

return settings