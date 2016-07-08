-- Side length of a pixel.
local PIXEL_SIZE = require("settings").PIXEL_SIZE

-- The dimensions of the screen.
local DISPLAY_W = 64
local DISPLAY_H = 32

-- Set the window to match the display.
function love.conf(t)
	t.window.title = "CHIP-8 Emulator"
	t.window.width = DISPLAY_W * PIXEL_SIZE
	t.window.height = DISPLAY_H * PIXEL_SIZE

	t.console = true
end