--[[
    This file creates the CHIP-8 object which emulates the CHIP-8 language.
    The CHIP-8 object can be created by calling CHIP8().
    To emulate a program, the bytes for the instructions of the program is
    loaded into memory by using chip8:load(table bytes) where the table
    contains opcodes. The emulation then is started by calling chip8:reset().
    The program runs by making calls to chip8:cycle(). Keyboard input can be
    controlled by using chip8:setKeyDown(int key, boolean isDown) where key is
    the key from 0-15 and isDown is whether or not the key is being held down.

    Information about the fields for the CHIP-8 object can be found where
    CHIP8.new() is defined.

    The emulator was made using documentation from here:
    http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
--]]

local bit = bit32 or bit

-- Load all of the instructions for CHIP-8.
local instructions = require("instructions")

-- The amount of instructions to run each cycle.
local INSTR_PER_CYCLE = require("settings").INSTR_PER_CYCLE

-- Length of each register.
local V_COUNT = 16

-- Number of keys on a keyboard.
local KEYBOARD_COUNT = 16

-- Amount of memory slots.
local MEM_SIZE = 0x1000
local STACK_SIZE = 16

-- The dimensions of the screen.
local DISPLAY_W = 64
local DISPLAY_H = 32

-- Sizes for CHIP 8 numbers.
local BYTE = 8

-- The mask for getting the instruction.
local MASK_INSTR = 0xF000

-- The starting location of any program.
local PROG_START = 0x200

-- Number of opcodes to skip to get to the next instruction.
local NEXT_INSTR = 2

-- The font sprites for hexadecimal digits.
local MEM_FONT = {
    0xF0, 0x90, 0x90, 0x90, 0xF0,   -- 0
    0x20, 0x60, 0x20, 0x20, 0x70,   -- 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0,   -- 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0,   -- 3
    0x90, 0x90, 0xF0, 0x10, 0x10,   -- 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0,   -- 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0,   -- 6
    0xF0, 0x10, 0x20, 0x40, 0x40,   -- 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0,   -- 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0,   -- 9
    0xF0, 0x90, 0xF0, 0x90, 0x90,   -- A
    0xE0, 0x90, 0xE0, 0x90, 0xE0,   -- B
    0xF0, 0x80, 0x80, 0x80, 0xF0,   -- C
    0xE0, 0x90, 0x90, 0x90, 0xE0,   -- D
    0xF0, 0x80, 0xF0, 0x80, 0xF0,   -- E
    0xF0, 0x80, 0xF0, 0x80, 0x80    -- F
}

-- CHIP-8 object definition.
local CHIP8 = {}
CHIP8.__index = CHIP8

-- Creates a new CHIP8 object.
function CHIP8.new()
    return setmetatable({
        V = {},             -- V0-Vf registers
        I = 0x0000,         -- I register
        DT = 0x0,           -- Delay timer
        ST = 0x0,           -- Sound timer
        PC = 0x0000,        -- The program counter
        SP = 0x0000,        -- The stack pointer
        running = false,    -- If false, then the CPU is paused
        drawing = false,    -- Whether or not something was drawn the last cycle
        memory = {},        -- The memory for the CPU
        stack = {},         -- The call stack.
        display = {},       -- Array of screen "pixel" bits.
        keyboard = {}       -- Array of which keys are being pressed
    }, CHIP8)
end

-- Initializes all of the registers and memory related fields.
function CHIP8:reset()
    -- Zero out all of the V registers.
    for i = 0, V_COUNT - 1 do
        self.V[i] = 0x00
    end
    
    -- Zero out the stack.
    for i = 0, STACK_SIZE - 1 do
        self.stack[i] = 0x0000
    end
    
    -- Fill in the memory locations.
    for i = 0, MEM_SIZE - 1 do
        -- Set 0x000-0x1FF to be the font sprites.
        if (i < #MEM_FONT) then
            self.memory[i] = MEM_FONT[i + 1]
        else
            self.memory[i] = 0x00
        end
    end
    
    -- Zero out the display.
    for i = 0, (DISPLAY_W * DISPLAY_H) - 1 do
        self.display[i] = 0x0
    end
    
    -- Start executing the program.
    self.PC = PROG_START
    self.running = true
end

-- Flags a given key as being pressed.
function CHIP8:setKeyDown(key, down)
    self.keyboard[key] = down
end

-- Fetch, load, and execute instructions. If successful, this function returns
-- nil, otherwise it returns the error message.
function CHIP8:cycle()
    -- Don't run if paused.
    if (not self.running) then
        return
    end

    -- Reset the drawing flag.
    self.drawing = false
    
    -- Fetch the next opcode.
    for i = 1, INSTR_PER_CYCLE do
        -- Don't run if paused.
        if (not self.running) then
            return
        end

        -- Make sure the next opcode is valid.
        if (self.PC >= MEM_SIZE) then
            return "program counter out of range"
        end

        local op = self.memory[self.PC]
        local op2 = self.memory[self.PC + 1]
        local opcode = bit.bor(bit.lshift(op, BYTE), op2)
        local instr = bit.band(opcode, MASK_INSTR)
        
        -- Decode the opcode.
        if (instructions[instr]) then
            -- Execute the opcode and update the program counter.
            self.PC = self.PC + NEXT_INSTR
            self.PC = instructions[instr](self, opcode) or self.PC
        else
            return "unknown opcode: "..("%04X"):format(opcode)
        end
    end
    
    -- Decrement the delay timer.
    if (self.DT > 0) then
        self.DT = self.DT - 1
    end
    
    -- Decrement the sound timer.
    if (self.ST > 0) then
        self.ST = self.ST - 1
    end
end

-- Loads a table of bytes into the CHIP-8 memory.
function CHIP8:load(program)
    for i = 1, #program do
        self.memory[PROG_START + (i - 1)] = program[i]
    end
end

setmetatable(CHIP8, {__call = CHIP8.new})

return CHIP8