-- The CHIP-8 emulator.
local CHIP8 = require("chip8")

-- The dimensions of the screen.
local DISPLAY_W = 64
local DISPLAY_H = 32

-- Side length for one pixel.
local PIXEL_SIZE = require("settings").PIXEL_SIZE

-- Mapping of keyboard key to CHIP-8 input.
local KEY_MAPPING = require("settings").KEY_MAPPING

-- The CHIP-8 emulator object.
local cpu

-- RGB value for being fully opaque.
local OPAQUE = 255

-- Load the emulator.
function love.load(args)
    local file = love.filesystem.newFile("ROM/"..require("settings").ROM)
    local status, result = file:open("r")

    if (status) then
        -- The game instructions.
        local game = {}

        -- Load each byte from the ROM into game.
        while (not file:isEOF()) do
            game[#game + 1] = file:read(1):byte()

            if (not game[#game]) then
                print("Failed to read ROM! ("..(game[#game] or "nil")..")")

                return
            end
        end

        file:close()

        -- Start the game.
        cpu = CHIP8()
        cpu:reset()
        cpu:load(game)
    else
        print(result)
        file:close()
    end
end

-- Run the CPU.
function love.update()
    if (cpu) then
        local result = cpu:cycle()

        if (result) then
            print("ERROR: "..result)
        end

        if (cpu.ST > 0) then
            print("BEEP!")
        end
    end
end

-- Draw the results on the screen.
function love.draw()
    -- Black background.
    love.graphics.clear(0, 0, 0, OPAQUE)

    if (not cpu) then
        return
    end

    -- Make each screen pixel white.
    love.graphics.setColor(OPAQUE, OPAQUE, OPAQUE, OPAQUE)

    -- Draw each screen pixel if active.
    for y = 0, DISPLAY_H - 1 do
        for x = 0, DISPLAY_W - 1 do
            if (cpu.display[x + (y * DISPLAY_W)] > 0) then
                love.graphics.rectangle("fill",
                                        x * PIXEL_SIZE, y * PIXEL_SIZE,
                                        PIXEL_SIZE, PIXEL_SIZE)
            end
        end
    end
end

-- Handle keyboard press.
function love.keypressed(key)
    if (cpu and KEY_MAPPING[key]) then
        cpu:setKeyDown(KEY_MAPPING[key], true)
    end
end

-- Handle keyboard release.
function love.keyreleased(key)
    if (cpu and KEY_MAPPING[key]) then
        cpu:setKeyDown(KEY_MAPPING[key], false)
    end
end