return
{
	WIDTH = display.contentWidth,
	HEIGHT = display.contentHeight,

	color =
	{
		[0] = {0.5, 0.5, 0.5},
		{0, 0, 1},
		{1, 0, 0},
		{0, 1, 1},
		{1, 1, 0},
		{1, 0, 1},
		{1, 0.5, 0},
		{0, 1, 0},
		{1, 1, 1},
	},

	pieces =
	{
		{ [0] = 0, -1,-1, -1,0, 0,0, 1,0 },		-- J
		{ [0] = 0, -1,-1, 0,-1, 0,0, 1,0 },		-- Z
		{ [0] = 0, -1,0, 0,0, 1,0, 2,0 },		-- I
		{ [0] = 0, 0,-1, 1,-1, 0,0, 1,0 },		-- O
		{ [0] = 0, -1,0, 0,0, 0,-1, 1,0 },		-- T
		{ [0] = 0, -1,0, 0,0, 1,0, 1,-1 },		-- L
		{ [0] = 0, -1,0, 0,0, 0,-1, 1,-1 },		-- S
		{ [0] = 0, 0,0, 0,0, 0,0, 0,0 },		-- dummy
	},

	info = {[0] = {0, 1, 2, 4}, {0, 1}, {2, 4, 6}},

	config =
	{
		{ -- P1
		cw0 = "i",
		right = "l",
		left = "j",
		soft = "k",
		hard = "s",
		cw = "d",
		ccw = "a",
		hold = "w",
	},
	{ -- P2
		cw0 = "numPad8",
		right = "numPad6",
		left = "numPad4",
		soft = "numPad5",
		hard = "down",
		cw = "right",
		ccw = "left",
		hold = "up",
	}
	}
}